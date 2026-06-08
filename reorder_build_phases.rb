require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |t| t.name == 'Runner' }

if runner_target
  embed_phase = runner_target.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' || phase.symbol_dst_subfolder_spec == :plug_ins }
  
  if embed_phase
    resources_index = runner_target.build_phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase) }
    
    if resources_index
      runner_target.build_phases.delete(embed_phase)
      runner_target.build_phases.insert(resources_index + 1, embed_phase)
      project.save
      puts "Successfully moved 'Embed App Extensions' right after 'Resources' (index #{resources_index + 1})."
    else
      puts "Error: Resources phase not found!"
    end
  else
    puts "Error: Embed App Extensions phase not found!"
  end
else
  puts "Runner target not found."
end
