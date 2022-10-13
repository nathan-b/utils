#!/usr/bin/ruby

# A script to read protobuf string dumps (.dams) and extract the container metadata
# Usage: ./containers.rb *.dams

$instance = ''
$containers = {}

while (f = ARGV.shift)
  ds = File.read(f)

  in_container = false
  in_label = false
  cont_id = ''
  container = {}
  lkey = ''
  ds.each_line { |line|
    if line.start_with?('instance_id')
      line =~ /instance_id: "(.+)"/
      if ($1 != $instance && !$instance.empty?())
        puts "Multiple instance IDs found (#{$instance} and #{$1})!"
      end
      $instance = $1
    end

    if in_container
      next if !in_label && line.start_with?('    ') # Don't read nested tags
      larr = line.split(':')
      if !in_label && larr.length == 2
        if (larr[0].strip == 'id')
          cont_id = larr[1].strip
          #container.store(larr[0].strip, larr[1].strip)
        elsif (larr[0].strip == 'name' || larr[0].strip == 'type')
          container.store(larr[0].strip, larr[1].strip)
        end
      end

      if line.rstrip == '}'
        in_container = false
        if cont_id.empty?
          puts "File #{f} has a container with no ID"
        else
          if $containers.has_key?(cont_id)
            $containers[cont_id]['count'] += 1
          else
            $containers.store(cont_id, container)
          end
        end
        container = {}
        cont_id = ''
      end

      if line.rstrip == '  }'
        in_label = false
      end

      if line.strip == 'labels {'
        in_label = true
      end

      if in_label && larr.length == 2
        if larr[0].strip == 'key'
          lkey = larr[1].strip
        elsif larr[0].strip == 'value'
          container['labels'].store(lkey, larr[1].strip)
        end

      end
    elsif line.rstrip == 'containers {'
      in_container = true
      container.store('count', 1)
      container.store('labels', {})
    end
  }
end

puts "Instance ID #{$instance}\n================================\n#{$containers.length} containers:"
$containers.each { |id, cont|
  puts "\tContainer #{id}"
  cont.each { |k,v|
    if k == 'labels'
      puts "\t\tLabels:"
      v.each { |l,q|
        puts "\t\t\t#{l}: #{q}"
      }
    else
      puts "\t\t#{k}: #{v}"
    end
  }
}
