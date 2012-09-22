# Assume mercurial and hg-git is installed
# sudo easy_install hg-git

hg_to_clone = {
  "artemis-esf/artemis-framework" => "https://code.google.com/p/artemis-framework",
  "artemis-esf/gamadu-starwarrior" => "https://code.google.com/p/gamadu-starwarrior",
  "artemis-esf/gamadu-tankz" => "https://code.google.com/p/gamadu-tankz",
  "artemis-esf/spaceship-warrior" => "https://code.google.com/p/spaceship-warrior",
  "artemis-esf/piemaster-artemoids" => "https://bitbucket.org/piemaster/artemoids",
}

BASE_DIR=`pwd`.strip

hg_to_clone.each_pair do |target, source|
  directory = "#{BASE_DIR}/#{File.basename(source)}"
  unless File.directory?(directory)
    puts "Directory #{directory} for repository #{source} does not exist. Cloning..."
    Dir.chdir(BASE_DIR)
    system "hg clone #{source} #{directory}"
    puts "In directory #{directory} make a bookmark of master for default, so a ref gets created."
    Dir.chdir(directory)
    system "hg bookmark -r default master"
  end
  puts "Updating directory #{directory} for repository #{source}."
  Dir.chdir(directory)
  system "hg pull"

  target = "git+ssh://git@github.com/#{target}.git"
  puts "Pushing directory #{directory} to git repository #{target}."
  system "hg push #{target}"
end