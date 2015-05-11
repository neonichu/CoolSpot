.PHONY: all pod

all:
	xcodebuild -workspace CoolSpot.xcworkspace -scheme CoolSpot \
		-sdk iphonesimulator CODE_SIGN_IDENTITY=-

pod:
	bundle install
	bundle exec pod install --no-repo-update
