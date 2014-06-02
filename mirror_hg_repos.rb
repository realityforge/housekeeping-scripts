# Assume mercurial and hg-git is installed
# sudo easy_install hg-git

hg_to_clone = {
  "artemis-esf/quake2-gwt-port" => "https://code.google.com/p/quake2-gwt-port",
  "artemis-esf/artemis-framework" => "https://code.google.com/p/artemis-framework",
  "artemis-esf/gamadu-starwarrior" => "https://code.google.com/p/gamadu-starwarrior",
  "artemis-esf/gamadu-tankz" => "https://code.google.com/p/gamadu-tankz",
  "artemis-esf/gamadu-spaceship-warrior" => "https://code.google.com/p/spaceship-warrior",
  "artemis-esf/piemaster-artemoids" => "https://bitbucket.org/piemaster/artemoids",
  "artemis-esf/piemaster-jario" => "https://bitbucket.org/piemaster/jario",
  "realityforge-experiments/vmstats" => "https://bitbucket.org/timconradinc/vmstats",
  "artemis-esf/apollo-entity-framework" => "https://code.google.com/p/apollo-entity-framework/",
  "artemis-esf/apollo-warrior" => "https://code.google.com/p/apollo-warrior/",
}

BASE_DIR=File.dirname(__FILE__) + "/repositories"

def sh(command)
  system command
  raise "Failed to execute command #{command} with exit #{$?}" if $?.to_i.to_s != "0"
end

hg_to_clone.each_pair do |target, source|
  directory = "#{BASE_DIR}/#{File.basename(source)}"
  unless File.directory?(directory)
    puts "Directory #{directory} for repository #{source} does not exist. Cloning..."
    Dir.chdir(BASE_DIR)
    sh "hg clone #{source} #{directory}"
    puts "In directory #{directory} make a bookmark of master for default, so a ref gets created."
    Dir.chdir(directory)
    sh "hg bookmark -r default master"
  end
  puts "Updating directory #{directory} for repository #{source}."
  Dir.chdir(directory)
  sh "hg pull"

  target = "git+ssh://git@github.com/#{target}.git"
  puts "Pushing directory #{directory} to git repository #{target}."
  sh "hg push #{target} | grep 'pushing to git+ssh'"
end
