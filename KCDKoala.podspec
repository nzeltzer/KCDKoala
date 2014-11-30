#
# Be sure to run `pod lib lint KCDKoala.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "KCDKoala"
  s.version          = "0.8.0"
  s.summary          = "An object manager for UITableView and UICollectionView."
  s.description      = <<-DESC
                       KCDKoala provides a simple, serialized interface for manipulating the contents of UICollectionView and UITableView instances through a storage class like interface.
                       DESC
  s.homepage         = "https://github.com/nzeltzer/KCDKoala"
  s.screenshots      = "http://www.piratepenguin.com/downloads/koala_api.gif"
  s.license          = 'MIT'
  s.author           = { "Nicholas Zeltzer" => "nik@piratepenguin.com" }
  s.source           = { :git => "https://github.com/nzeltzer/KCDKoala.git", :tag => s.version.to_s }
  s.social_media_url = 'https://alpha.app.net/nink'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'KCDKoala' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
end
