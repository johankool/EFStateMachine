Pod::Spec.new do |s|
  s.name         = "EFStateMachine"
  s.version      = "0.3.0"
  s.summary      = "A Simple State Machine in Swift."
  s.description  = <<-DESC
A Simple State Machine in Swift

Highlights of this state machine:

* uses enums for states
* support for associate types in state enums
* runs callback handler on state changes
                   DESC
  s.homepage     = "https://github.com/Egeniq/EFStateMachine"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Johan Kool" => "johan@koolistov.net" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.source       = { :git => "https://github.com/Egeniq/EFStateMachine.git", :tag => "v#{s.version}" }
  s.source_files = "StateMachine/*.swift"
  s.requires_arc = true
end
