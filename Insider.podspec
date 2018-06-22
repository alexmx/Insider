
Pod::Spec.new do |s|

  s.name          = "Insider"
  s.version       = "1.0.1"
  s.summary       = "Insider is an utility framework which sets a backdoor into your app for testing tools like Appium, Calabash, Frank, etc."

  s.description   = <<-DESC
                      Insider is an utility framework which sets a backdoor into your app for testing tools like Appium, Calabash, Frank, etc.
                      Insider runs an HTTP server inside the application and listens for commands (RPCs).
                    DESC


  s.homepage              = "https://github.com/alexmx/Insider"
  s.license               = "MIT"
  s.authors               = "Alex Maimescu"

  s.platform              = :ios
  s.ios.deployment_target = '8.0'

  s.source                = { :git => "https://github.com/alexmx/Insider.git", :tag => "v#{s.version}" }
  s.source_files          = "Insider/**/*.{swift}", "Libs/**/*.{h,m,swift}"

  s.libraries             = 'xml2', 'z'

end
