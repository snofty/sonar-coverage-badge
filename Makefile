# use the tools as dev dependencies rather than installing them globaly
# it lets you handle specific versions of the tooling for each of your projects
MOCHA=node_modules/.bin/mocha
ISTANBUL=node_modules/.bin/istanbul
JSHINT=node_modules/.bin/jshint

# test files must end with ".test.js"
TESTS=$(shell find test/ -name "*.test.js")

all: clean test realtest

clean:
	rm -rf reports

test:
	npm run-script coverage

realtest:
	node src/index.js &
	sleep 2
	curl "http://127.0.0.1:8087/?server=nemo.sonarqube.org&resource=junit:junit&metrics=coverage&ssl=true" > temp.svg
	open temp.svg
	sleep 5
	rm -f temp.svg
	pkill node

coverage:
	@# check if reports folder exists, if not create it
	@test -d reports || mkdir reports
	$(ISTANBUL) instrument --output src-cov src

	@# move original src code and replace it by the instrumented one
	mv src src-orig
	sleep 3
	mv src-cov src
	sleep 3

	@# tell istanbul to only generate the lcov file
	ISTANBUL_REPORTERS=lcovonly $(MOCHA) -R mocha-istanbul $(TESTS)

	@# place the lcov report in the report folder, remove instrumented code
	@# and reput src at its place
	mv lcov.info reports/coverage.lcov
	rm -rf src
	mv src-orig src
	genhtml reports/coverage.lcov --output-directory reports/

jshint:
	$(JSHINT) src test --show-non-errors

sonar:
	@# add the sonar sonar-runner executable to the PATH
	sonar-runner

.PHONY: clean test coverage jshint sonar all
