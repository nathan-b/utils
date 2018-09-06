#!/usr/bin/ruby

class Agent
	def initialize(dragent = '')
		@dragent = dragent	
	end

	def get_dragent
		if @dragent == ''
			return ''
		end

		return "-v #{@dragent}:/opt/draios/etc/dragent.yaml"
	end
end

@detached = true
@profile = 'default'
@dry_run = false


@agents = {
	'staging' => Agent.new('~/dragent_files/nb.dragent.as2.yaml'), 
	'default' => Agent.new()
}

def parse_args
	while (a = ARGV.shift)
		case a
		when '--dry-run'
			@dry_run = true
		when '-d'
			@detached = true
		when '-i'
			@detached = false
		when '-p'
			@profile = ARGV.shift
			if (!@agents.has_key?(@profile))
				puts "Unknown profile #{@profile}"
				exit(-1)
			end
		else
			puts "Unrecognized flag #{a}"
			exit(-1)
		end
	end
end

parse_args

d = '-d'
if !@detached
	d = '-it'
end

a = @agents[@profile]

cmd = "docker run #{d} --rm --name sysdig-agent --privileged --net host --pid host #{a.get_dragent} -v /var/run/docker.sock:/host/var/run/docker.sock -v /dev:/host/dev -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro agent"

if (@dry_run) 
	puts cmd
	exit(0)
end

`#{cmd}`

