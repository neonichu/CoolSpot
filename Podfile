plugin 'cocoapods-keys', {
  :project => 'CoolSpot',
  :keys => [
    'SpotifyClientId',
    'SpotifyTokenSwapURL',
    'SpotifyTokenRefreshURL'
]}

platform :ios, "8.0"
use_frameworks!

pod 'BBUDeviceColors'
pod 'KeychainAccess'
pod 'MMWormhole'
pod 'SpotifySDK', :git => 'https://github.com/neonichu/ios-sdk'
#pod 'SpotifySDK', :path => '../../Sources/spotify-ios-sdk'

target 'CoolSpot WatchKit Extension', :exclusive => true do

pod 'MMWormhole'

end

target "SpotMenu" do

platform :osx, "10.10"

pod 'KeychainAccess'
pod 'SpotifySDK', :git => 'https://github.com/neonichu/ios-sdk' # No OS X :(
pod 'SPTMediaKeys', :git => 'https://github.com/neonichu/SPMediaKeyTap.git'

end
