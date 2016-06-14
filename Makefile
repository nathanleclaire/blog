watch:
	hugo server -b localhost:1313/ --watch

deploy:
	rm -rf public/
	hugo
	aws s3 sync --delete public/ s3://nathanleclaire.com --region us-west-1
