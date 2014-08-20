while true
do
	rails runner 'FeedsFetcher.new.refresh_all'
	sleep 30
done

