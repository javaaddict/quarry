#!/usr/bin/ruby

$:.unshift File.dirname(__FILE__)
require 'quarry.rb'


def find_all_dependencies(whitelist_pkgs, existing_pkgs)
  # existing_pkgs is just a convenient way to get package dependencies without loading gem index
  unvisited = whitelist_pkgs.dup
  visited = []

  while p = unvisited.pop
    next if visited.include?(p)

    visited << p
    arch_deps = existing_pkgs[p][2].select{|n| n.start_with?('ruby-')}.map{|n| arch_to_pkg(n)}
    unvisited += arch_deps
  end

  return visited
end

init()
existing_packages = load_arch_packages()
whitelist_packages = load_packages('whitelist_packages')

# 1. Find packages that are not needed for whitelist
required_pkgs = find_all_dependencies(whitelist_packages, existing_packages)
unneeded_pkgs = existing_packages.keys - required_pkgs
# let's leave existing head packages and drop only versioned one
unneeded_pkgs.reject!{|p| p[1].nil?}

unless unneeded_pkgs.empty?
  unneeded = unneeded_pkgs.map{|p| pkg_to_arch(*p)}.join(' ')
  puts 'repo-remove quarry.files.tar.xz ' + unneeded
  puts 'repo-remove quarry.db.tar.xz ' + unneeded
end


# 2. Find all packages in index directory that are not present in repo (i.e. old versions)
all_files = existing_packages.values.map{|v| [v[3], v[3]+'.sig']}.flatten
Dir[INDEX_DIR + '/*.pkg.tar.xz{,.sig}'].each {|f|
  name = File.basename(f)

  puts "rm #{name}" unless all_files.include?(name)
}
