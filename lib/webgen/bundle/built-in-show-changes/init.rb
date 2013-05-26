# -*- encoding: utf-8 -*-
#
# This file initializes the show-changes built-in extension.

option('destination.show_changes', false) do |val|
  raise "The value has to be 'true' or 'false'" unless val == true || val == false
  val
end

data = nil

website.blackboard.add_listener(:before_node_written, 'destination.show_changes') do |node|
  next unless website.config['destination.show_changes'] && node.is_file? && !node['no_output']
  webgen_require('diff/lcs', 'diff-lcs')
  webgen_require('diff/lcs/hunk', 'diff-lcs')
  if website.ext.destination.exists?(node.dest_path)
    data = website.ext.destination.read(node.dest_path)
  else
    data = nil
  end
end

website.blackboard.add_listener(:after_node_written, 'destination.show_changes') do |node, content|
  next unless website.config['destination.show_changes'] && node.is_file? && !node['no_output']
  if data.nil?
    website.logger.info { "New destination path <#{node.dest_path}>" }
    next
  end
  new_data = (content.kind_of?(String) ? content : content.data).force_encoding('ASCII-8BIT')

  binary = data[0...4096]["\0"] || new_data[0..4096]["\0"]
  if binary
    if data.force_encoding('BINARY') != new_data.force_encoding('BINARY')
      website.logger.info { "Path <#{node.dest_path}> differs" }
    end
  else
    data = data.split(/\n/).map! {|e| e.chomp }
    new_data = new_data.split(/\n/).map! {|e| e.chomp }
    diffs = Diff::LCS.diff(data, new_data)
    next if diffs.empty?

    length_diff = 0
    diffs.each do |piece|
      hunk = Diff::LCS::Hunk.new(data, new_data, piece, 0, length_diff)
      length_diff = hunk.file_length_difference

      hunk.diff(:unified).split(/\n/).each do |line|
        website.logger.info { line }
      end
    end
  end
end

