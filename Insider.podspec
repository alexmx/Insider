
Pod::Spec.new do |s|

  s.name          = "Insider"
  s.version       = "0.1"
  s.summary       = "Set a communication channel between your app and external testing environments."

  s.description   = <<-DESC
                      Insider is a testing utility framework which sets an HTTP communication channel between the app and testing environments like Appium, Calabash, Frank, etc.
                    DESC
  s.homepage      = "https://github.com/alexmx/Insider"
  s.license       = "MIT"
  s.authors       = { "Alex Maimescu" => "maimescu.alex@gmail.com" }

  s.platform      = :ios
  s.source        = { :path => "." }
  s.source_files  = "Insider/**/*.{h,m,swift}"

end
