
.PHONY: watch

start:
	./node_modules/.bin/coffee ./server/index.litcoffee

watch:
	export PATH="./node_modules/.bin:$(PATH)"; ./node_modules/.bin/nodemon --watch ./server -e .litcoffee,.coffee,.js ./server/index.litcoffee
