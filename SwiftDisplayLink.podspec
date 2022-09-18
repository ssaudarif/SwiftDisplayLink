#
#  Be sure to run `pod spec lint SwiftDisplayLink.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "SwiftDisplayLink"
  spec.version      = "0.0.1"
  spec.summary      = "SwiftDisplayLink is a small libraray that provides abstraction of display links for macOS and iOS."
  spec.homepage     = "https://github.com/ssaudarif/SwiftDisplayLink"
  spec.description = 'This library provides a timer type of functionality that is driven using '  \
                     'Dislaylinks. The library supports iOS and macOS platform. For iOS we are '  \
                     'using CADisplayLink and for macOS we are using CVDisplayLink. With this '   \
                     'library you can create a variable duration timer with ease and this will '  \
                     'also provide a way to make frame ready before the actual frame hit happens. '
  spec.license      = "MIT"

  spec.author       = { "Syed Saud Arif" => "syedsaudarif@gmail.com" }

  spec.osx.deployment_target = '10.11'
  spec.ios.deployment_target = '11.0'
  # Note it does support iOS below 11.0 but due to a limitation of cocoapos we cannot specify less than 11 here.
  # for more info check - https://github.com/CocoaPods/CocoaPods/issues/8915
  
  spec.source       = { :git => "https://github.com/ssaudarif/SwiftDisplayLink.git", :tag => spec.version.to_s }


  spec.source_files  = "Sources", "Sources/**/*.{swift}"
  spec.swift_versions = ['4.2']
  
  # spec.test_spec 'Tests' do |test_spec|
  #   test_spec.source_files = "Tests/**/*.{swift}"
  # end
  
  # spec.exclude_files = "Classes/Exclude"
  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  spec.requires_arc = true

end
