require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'SafakWidgetExtension'
runner_target = project.targets.find { |t| t.name == 'Runner' }

if !runner_target
  puts "Error: Runner target not found!"
  exit 1
end

# Find or create the Widget Extension target
target = project.targets.find { |t| t.name == target_name }

if target
  puts "Target '#{target_name}' already exists."
else
  # Create Widget Extension target
  target = project.new_target(:app_extension, target_name, :ios, '14.0')
  target.product_type = 'com.apple.product-type.app-extension'
  puts "Created target '#{target_name}'."
end

# Find development team from Runner target
development_team = nil
runner_target.build_configurations.each do |config|
  val = config.build_settings['DEVELOPMENT_TEAM']
  if val && !val.empty?
    development_team = val
    break
  end
end

# Configure target build settings
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'SafakWidgetExtension/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.bayesa.ios.safaksayar2026.SafakWidgetExtension'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SafakWidgetExtension/SafakWidgetExtension.entitlements'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone, iPad
  config.build_settings['PRODUCT_NAME'] = 'SafakWidgetExtension'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  if development_team
    config.build_settings['DEVELOPMENT_TEAM'] = development_team
  end
end

# Set CODE_SIGN_ENTITLEMENTS on the host Runner target
runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Find or create file group
group = project.main_group.find_subpath('SafakWidgetExtension', true)

# Add file references
swift_file = group.files.find { |f| f.path == 'SafakWidgetExtension.swift' } || group.new_file('SafakWidgetExtension/SafakWidgetExtension.swift')
info_plist = group.files.find { |f| f.path == 'Info.plist' } || group.new_file('SafakWidgetExtension/Info.plist')
entitlements = group.files.find { |f| f.path == 'SafakWidgetExtension.entitlements' } || group.new_file('SafakWidgetExtension/SafakWidgetExtension.entitlements')

# Associate source files with target build phases
# Clear existing source files to prevent duplicates
sources_phase = target.source_build_phase
sources_phase.files.each do |build_file|
  sources_phase.remove_build_file(build_file)
end
target.add_file_references([swift_file])

# Add target dependency to Runner
unless runner_target.dependencies.any? { |dep| dep.target == target }
  dependency = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
  dependency.target = target
  runner_target.dependencies << dependency
  puts "Added dependency on '#{target_name}' to 'Runner'."
end

# Embed extension in Runner's Copy Files phase
embed_phase = runner_target.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' || phase.symbol_dst_subfolder_spec == :plug_ins }
if !embed_phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  puts "Created 'Embed App Extensions' build phase."
end

# Add product reference to embed phase if not already present
unless embed_phase.files.any? { |f| f.file_ref == target.product_reference }
  embed_phase.add_file_reference(target.product_reference)
  puts "Embedded '#{target_name}' product in 'Runner'."
end

project.save
puts "Successfully configured Xcode project for Widget Extension!"
