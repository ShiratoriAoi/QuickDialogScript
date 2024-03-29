#
# Be sure to run `pod lib lint QuickDialogScript.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'QuickDialogScript'
  s.version          = '1.3.0'
  s.summary          = 'You can make dialogs by text files.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This pod allows you to create custom dialogs by writing text files. 
  It parses the text with a parser combinator and generates a dialog based on the parsed information.
                       DESC
  s.homepage         = 'https://github.com/ShiratoriAoi/QuickDialogScript'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Aoi SHIRATORI' => 'aoy.shiratori@gmail.com' }
  s.source           = { :git => 'https://github.com/ShiratoriAoi/QuickDialogScript.git' , :tag => s.version}
  s.social_media_url = 'https://twitter.com/ShiratoriAoi'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'QuickDialogScript/Classes/**/*'
  
  # s.resource_bundles = {
  #   'QuickDialogScript' => ['QuickDialogScript/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'QuickDialog'
  s.dependency 'FootlessParser', '~> 0.5.1'
end
