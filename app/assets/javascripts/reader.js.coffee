app = angular.module 'reader', ['ngSanitize']

app.run ($http) ->
  token = $('meta[name=csrf-token]').attr('content')
  $http.defaults.headers.common['X-CSRF-Token'] = token

  $http.defaults.headers.patch = 'Content-Type': 'application/json;charset=utf-8'

replaceArrayContent = (array, newContent) ->
  array.splice 0, array.length, newContent...

makeSnippet = (html) ->
  html.replace /<\/?[^>]*>/gi, (string) ->
    if string.slice(0, 3) == '<a '
      '<a target="_blank"' + string.slice(2)
    else if string == '</a>'
      string
    else ''

dateToAge = ($dateFilter, date) ->
  currentTime = Date.now() / 1000
  time = date.getTime() / 1000
  diff = Math.floor(currentTime - time)

  minute = 60; hour = minute * 60
  day = hour * 24; week = day * 7

  if diff < hour
    Math.ceil(diff / minute) + 'm'
  else if diff < day
    Math.floor(diff / hour) + 'h'
  else if diff < week
    Math.floor(diff / day) + 'd'
  else
    $dateFilter(date, 'dd.MM.yy')

app.directive 'sortable', ->
  restrict: 'A'
  scope: onSwap: '&'

  link: (scope, element, attrs) ->
    start = stop = null

    el = $(element)
      .disableSelection()
      .sortable
        start: (event, ui) ->
          start = ui.item.index()

        stop: (event, ui) ->
          stop = ui.item.index()
          scope.onSwap()(start, stop)
          true

app.directive 'subscribeDialog', ($document) ->
  restrict: 'C'
  scope: callback: '&', visible: '='
  template: '''
    <div class="caption">type in URL and press Enter</div>
    <input ng-model="url">
    <div class="snippet">e.g., reddit.com</div>
  '''

  link: (scope, element, attrs) ->
    enterKeyCode = 13
    escKeyCode = 27

    input = element.find 'input'

    scope.$watch 'visible', (value) ->
      if value
        element.show()
        input.focus()
      else
        element.hide()

    input.on 'keyup', (event) ->
      if event.keyCode == enterKeyCode
        scope.callback()(scope.url)
        scope.url = ''
        scope.visible = false
        scope.$apply()

    $document.on 'keyup', (event) ->
      if event.keyCode == escKeyCode
        scope.visible = false
        scope.$apply(0)

app.directive 'pressable', ->
  restrict: 'C'

  link: (scope, element, attrs) ->
    element.on 'mousedown', -> $(this).addClass 'pressed'
    element.on 'mouseup', -> $(this).removeClass 'pressed'

app.constant 'Mixins',

  addSubscribeButtonBehavior: ($scope, $document, $http, $timeout) ->

    highlightFeed = (feed) ->
      feed.highlighted = true
      $timeout (-> feed.highlighted = false), 1000

    $scope.isSubscribeDialogVisible = false

    $scope.subscribeCallback = (url) ->
      return unless url

      protocolRegexp = /^https?:\/\//
      url = 'http://' + url unless url.match(protocolRegexp)
      params = url: url, position: $scope.feeds.length

      dummyFeed =
        url: url
        title: url.replace(protocolRegexp, '')
        isLoading: true
      $scope.feeds.push dummyFeed

      $http.post '/api/feeds/', params
        .success (response) ->
          dummyIndex = null
          copyIndex = null
          for feed, index in $scope.feeds
            dummyIndex = index if dummyFeed == feed
            copyIndex = index if response.feed.id == feed.id
          $scope.feeds[copyIndex || dummyIndex] = response.feed
          $scope.feeds.splice(dummyIndex, 1) if dummyIndex && copyIndex
          highlightFeed response.feed

    $scope.subscribeButtonClick = ->
      $scope.isSubscribeDialogVisible = !$scope.isSubscribeDialogVisible


  addSortableBehavior: ($scope, $http) ->

    $scope.swapFeedPositions = (start, stop) ->
      subarray = $scope.feeds.splice(start, 1)
      $scope.feeds.splice(stop, 0, subarray[0])

      for feed, index in $scope.feeds
        feed.position = index
        params = position: index
        $http method: 'patch', url: "/api/feeds/#{feed.id}/", data: params

      $scope.$apply()


  addInfiniteScrollBehavior: ($scope, $http) ->
    requestLaunched = false

    $doc = $(document)

    $doc.scroll ->
      return if $scope.viewingFavorite

      $el = $('.entries-panel')
      scrollTop = $doc.scrollTop()
      scrollBottom = scrollTop + $(window).innerHeight()
      scrollHeight = $doc.height()

      if scrollBottom + 200 > scrollHeight
        return if $scope.entries.length == 0
        lastEntry = $scope.entries[$scope.entries.length - 1]
        $scope.loadEntries $scope.selectedFeed, 'after', lastEntry.id

      if scrollTop - 200 < 0
        return if $scope.entries.length == 0
        firstEntry = $scope.entries[0]
        $scope.loadEntries $scope.selectedFeed, 'before', firstEntry.id
          .success ->
            $document = $(document)
            initialHeight = $document.height()

            setTimeout ->
              deltaHeight = $document.height() - initialHeight
              scrollTop = $document.scrollTop()
              $document.scrollTop(scrollTop + deltaHeight)


  addFeedButtonsBehavior: ($scope, $http) ->

    $scope.refreshFeed = ->
      $scope.entries = []
      feed = $scope.selectedFeed
      $http.post "/api/feeds/#{feed.id}/refresh/"
        .success (response) ->
          index = $scope.findFeedIndex(feed)
          $scope.feeds[index] = response.feed
          $scope.selectFeed(response.feed)

    $scope.markAllAsRead = ->
      feed = $scope.selectedFeed
      feed.unreadEntriesCount = 0
      url = "/api/feeds/#{feed.id}/entries/mark_all_as_read"
      data = before: feed.lastEntryId
      $http.post url, data
        .success -> $scope.selectFeed(feed)
      e.isRead = true for e in $scope.entries

    $scope.batchMarked = []
    $scope.cancelBatchMarking = ->
      $scope.expandedEntry?.expanded = false
      for entry in $scope.batchMarked
        entry.isRead = false

      feed = $scope.selectedFeed
      url = "/api/feeds/#{feed.id}/entries/set_read_status"
      data = ids: (e.id for e in $scope.batchMarked), value: false
      $http.post url, data

      feed.unreadEntriesCount += $scope.batchMarked.length
      replaceArrayContent $scope.batchMarked, []

    $scope.unsubscribe = ->
      feed = $scope.selectedFeed
      $http.delete "/api/feeds/#{feed.id}/"
      index = $scope.findFeedIndex(feed)
      $scope.feeds.splice(index, 1)
      $scope.selectFeed($scope.feeds[0])


  addFeedsPanelBehavior: ($scope, $http, $sanitize, $filter) ->
    $scope.selectedFeed = null
    $scope.feeds = []

    $http.get '/api/feeds'
      .success (response) ->
        response.feeds.sort (a, b) -> a.position - b.position
        replaceArrayContent $scope.feeds, response.feeds
        $scope.selectFeed(response.feeds[0])

    setInterval ->
      $scope.updateUnreadEntriesCount()
    , 30 * 1000

    $scope.selectFeed = (feed) ->
      replaceArrayContent $scope.entries, []
      feed.isLoading = true

      $http.get "/api/feeds/#{feed.id}/"
        .success (response) ->
          $scope.viewingFavorite = false
          $scope.selectedFeed = feed = response.feed

          index = $scope.findFeedIndex(feed)
          $scope.feeds[index] = feed

          $scope.initializeEntry(entry) for entry in feed.entries
          replaceArrayContent $scope.entries, feed.entries
          replaceArrayContent $scope.batchMarked, []

          setTimeout -> $scope.scrollToUnreadEntry()

    $scope.showFavorites = ->
      $http.get "/api/entries/favorites"
        .success (response) ->
          $scope.viewingFavorite = true
          $scope.selectedFeed = null
          for entry in response.entries
            feed = $scope.findFeedById(entry.feedId)
            entry.feed = feed
            $scope.initializeEntry entry
          replaceArrayContent $scope.entries, response.entries

    $scope.initializeEntry = (entry) ->
      entry.title ||= '(no title)'
      entry.snippet = $sanitize(makeSnippet(entry.content))
      entry.content = entry.content.replace(/^\s*<br\s*\/?\s*>/g, '')
      entry.age = dateToAge($filter('date'), new Date(entry.createdAt))

    $scope.scrollToUnreadEntry = ->
      $(document).scrollTop(1)
      for entry, index in $scope.entries
        unless entry.isRead
          elHeight = $('.entry').outerHeight()
          scrollTo = Math.max(1, (index - 2.5) * elHeight)
          $(document).scrollTop(scrollTo)
          break

    $scope.updateUnreadEntriesCount = ->
      $http.get '/api/feeds'
        .success (response) ->
          for feed in response.feeds
            oldFeed = $scope.findFeedById(feed.id)
            oldFeed.unreadEntriesCount = feed.unreadEntriesCount

    $scope.findFeedIndex = (feed) ->
      for f, index in $scope.feeds
        return index if f.id == feed.id

    $scope.findFeedById = (feedId) ->
      for feed in $scope.feeds
        return feed if feed.id == feedId


  addEntriesPanelBehavior: ($scope, $http) ->
    $scope.entries = []
    $scope.mouseOnEntry = null
    $scope.mouseOnEntryEl = null
    $scope.peekEntry = false

    emptyFn = -> this
    dummyHttpPromise = success: emptyFn, finally: emptyFn, error: emptyFn

    isLimitReached = (feed, requestType) ->
      (feed.topReached && requestType == 'before') ||
      (feed.bottomReached && requestType == 'after')

    $scope.loadEntries = (feed, requestType, limitingEntryId) ->
      return dummyHttpPromise if feed.requestLaunched || isLimitReached(feed, requestType)

      feed.requestLaunched = true
      params = {}
      params[requestType] = limitingEntryId

      promise = $http.get "/api/feeds/#{feed.id}/entries/", params: params
        .success (response) ->
          if requestType == 'before'
            addMethod = 'unshift'
            limitProp = 'topReached'
          else
            addMethod = 'push'
            limitProp = 'bottomReached'

          feed[limitProp] = response.entries.length == 0

          for entry in response.entries
            if entry.id > feed.lastEntryId
              feed.bottomReached = true
              break
            $scope.initializeEntry entry
            $scope.entries[addMethod] entry

      promise.finally -> feed.requestLaunched = false
      promise

    clearBatchSelection = -> $('.batch-selected').removeClass('batch-selected')
    openNewTab = (event) -> event.ctrlKey || event.shiftKey || event.metaKey

    entryFakeClick = (event) ->
      $target = $(event.target)
      entryButtonClicked = $target.hasClass('entry-button')

      return if entryButtonClicked
      titleClicked = $target.hasClass('title')
      peekButtonClicked = $target.hasClass('peek-button')

      replaceArrayContent $scope.batchMarked, [] unless peekButtonClicked || $scope.mouseOnEntry.isRead

      feed = $scope.selectedFeed
      if $scope.peekEntry
        url = "/api/entries/#{$scope.mouseOnEntry.id}/"
        params = entry: { is_read: true }
        $http url: url, data: params, method: 'patch'
      else
        url = "/api/feeds/#{feed.id}/entries/mark_all_as_read"
        data = before: $scope.mouseOnEntry.id
        $http.post url, data

      for entry in $scope.entries
        unless $scope.peekEntry || entry.isRead
          entry.isRead = true
          feed.unreadEntriesCount -= 1
          $scope.batchMarked.push entry

        if entry == $scope.mouseOnEntry
          feed.unreadEntriesCount -= 1 if $scope.peekEntry && !entry.isRead && !$scope.viewingFavorite
          entry.isRead = true
          if event.target.tagName != 'A' || titleClicked || peekButtonClicked
            if event.button == 0 && !openNewTab(event)
              $scope.toggleEntryExpansion(entry)
          break

      $scope.$apply()

    $scope.scrollToExpandedEntry = ->
      details = $('.entry-list-row > .details')

      listRow = details.parent()
      listRowTop = listRow.offset().top

      $document = $(document)
      scrollTop = $document.scrollTop()
      windowHeight = $(window).innerHeight()

      if scrollTop + windowHeight < listRowTop + 100 || scrollTop > listRowTop
        $document.scrollTop(listRowTop - 100)

    $scope.toggleEntryExpansion = (entry) ->
      if entry.expanded
        entry.expanded = false
        $scope.expandedEntry = null
      else
        $scope.expandedEntry.expanded = false if $scope.expandedEntry
        $scope.expandedEntry = entry
        entry.expanded = true
        setTimeout ->
          $('.entry-list-row > .details > .content a').attr(target: '_blank')
          $scope.scrollToExpandedEntry()

    $scope.toggleFavoriteStatus = (entry) ->
      entry.isFavorite = !entry.isFavorite
      params = entry: { is_favorite: entry.isFavorite }
      $http url: "/api/entries/#{entry.id}/", data: params, method: 'patch'

    $(document)
      .on 'mouseenter', '.entry', (event) ->
        index = $(this).parent().index()
        $scope.mouseOnEntry = $scope.entries[index]
        $scope.mouseOnEntryEl = $(this)

      .on 'mouseleave', '.entry', (event) ->
        $scope.mouseOnEntry = null
        $scope.mouseOnEntryEl = null
        $scope.peekEntry = null
        clearBatchSelection()

      .on 'mousemove', '.entry', (event) ->
        peekEntry = $scope.viewingFavorite ||
                    $(event.target).hasClass('peek-button') ||
                    $(event.target).hasClass('entry-button')
        clearBatchSelection()
        $scope.mouseOnEntryEl
          .parent().prevAll().slice(0, 100)
          .not('.is-read').addClass('batch-selected') unless peekEntry
        $scope.peekEntry = peekEntry

      .on 'mousedown', '.entry', (event) ->
        $target = $(event.target)
        mouseleave = ->
          $target.off 'mouseleave', mouseleave
          $target.off 'mouseup', mouseup
        mouseup = (event) ->
          clearBatchSelection()
          entryFakeClick event
          mouseleave()
        $target.mouseleave mouseleave
        $target.mouseup mouseup

      .on 'click', '.entry', (event) ->
        $target = $(event.target)
        titleClicked = $target.hasClass('title')
        peekButtonClicked = $target.hasClass('peek-button')

        if event.button == 0 && (titleClicked || peekButtonClicked)
          event.preventDefault() unless openNewTab(event)

app.controller 'ReaderCtrl', ($scope, $http, $sanitize, $document, $filter, $timeout, Mixins) ->

  Mixins.addSubscribeButtonBehavior($scope, $document, $http, $timeout)
  Mixins.addSortableBehavior($scope, $http)
  Mixins.addInfiniteScrollBehavior($scope, $http)
  Mixins.addFeedButtonsBehavior($scope, $http)
  Mixins.addFeedsPanelBehavior($scope, $http, $sanitize, $filter)
  Mixins.addEntriesPanelBehavior($scope, $http)

