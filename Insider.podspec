
Pod::Spec.new do |s|

  s.name          = "Insider"
  s.version       = "0.1"
  s.summary       = "Set a communication channel between your app and external testing environments."

  s.description   = <<-DESC
                      Insider is a testing utility framework which sets an HTTP communication channel between the app and testing environments like Appium, Calabash, Frank, etc.
                    DESC


  s.homepage              = "https://github.com/alexmx/Insider"
  s.license               = "MIT"
  s.authors               = { "Alex Maimescu" => "maimescu.alex@gmail.com" }

  s.platform              = :ios
  s.ios.deployment_target = '8.0'

  s.source                = { :git => "https://github.com/alexmx/Insider.git", :tag => "v#{s.version}" }
  s.source_files          = "Insider/**/*.{swift}", "Libs/**/*.{h,m,swift}"

  s.libraries             = 'xml2', 'z'

end
