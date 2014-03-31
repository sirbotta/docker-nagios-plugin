#!/usr/bin/ruby
require 'nagiosplugin'
require 'slop'


#TODO need to parse args like anormale nagios plugin
opts = Slop.parse do
  banner 'Usage: foo.rb [options]'

  on 'w', 'warning','threshold for worning'
  on 'c', 'critical', 'threshold for critical'
  on 'v', 'verbose', 'Enable verbose mode'
end

# if ARGV is `--name Lee -v`
opts.verbose?  #=> true
#puts opts.to_hash   #=> {:name=>"Lee", :password=>nil, :verbose=>true}

# simple helpers to find if a string is a number
class String
  def is_number?
    true if Float self rescue false
  end
end


class DockerInfo < NagiosPlugin::Plugin
  @critical = false
  @warning = false
  @ok = false
  
  # initialize with a call to docker info
  def initialize
    cmd = 'docker info 2>&1'
    @info = {}
    IO.popen(cmd).each do |line|
      if(line.include?("Cannot connect") || line.include?("permission denied"))
        @critical = true
        @info["CRITICAL"]=line
      else
        l=line.split(':')
        @info[l[0].delete(' ')]=l[1][0..-2]
      end
    end.close
    @ok =  $?.success?
    
    
    #@info.delete("WARNING")# remove for now warning from docker info
    @warning = @info.has_key?("WARNING")
  end

  def critical?
    @msg=@info["CRITICAL"]
    @critical
  end

  def warning?
    @msg=@info["WARNING"]
    @warning 
  end

  def ok?
    perf_data = "|"
    @msg = ""
    @info.each do |label,val|
      if (val.is_number?)
         perf_data+="#{label}=#{val.delete(' ')} ,"
      else
         @msg+="#{label} is #{val.delete(' ')} ,"
      end
    end
    @msg=@msg[0..-2] + perf_data[0..-2]

    @ok
  end
  
   
  def message
    @msg
  end
end

#call the script and print the result
DockerInfo.check


