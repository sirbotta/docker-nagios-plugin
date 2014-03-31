#!/usr/bin/ruby
require 'nagiosplugin'
require 'slop'

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
  
  # initialize parsing parameters and running the docker info
  def initialize
    opts = Slop.parse do
      banner 'Usage: docker_info [options]'

      on 'w', 'warning=','Check containers, raise warning if bigger(outside) than the threshold', optional: true
      on 'c', 'critical=', 'Check containers, raise critical if bigger(outside) than the threshold', optional: true
      #on 'v', 'verbose', 'Enable verbose mode', optional: true TODO
      on :h, :help, 'Print this help message', optional: true, :tail => true do
        puts help
        exit
      end
    end
   
    cmd = '/usr/bin/docker info 2>&1'
    @info = {}
    #used popen to manipulate the stdout into and hashm, and check early critical problmes
    IO.popen(cmd).each do |line|
      if(line.include?("Cannot connect") || line.include?("permission denied"))
        @info["CRITICAL"]=line
      else
        l=line.split(':')
        @info[l[0].delete(' ')]=l[1][0..-2]
      end
    end.close# close the IO to get the result in $?
    #by defoult if docker info return data the plugin return success
    @ok =  $?.success?
    
    #@info.delete("WARNING")# uncoment to ignore swap warning

    #check if bypassed warning threshold
    if(opts["warning"])
      if(@info["Containers"].to_i > opts["warning"].to_i)
        @info["WARNING"]+=" Current #{@info["Containers"]} container/s with a warning threshold of #{opts["warning"].to_i} "
      end
    end
    
    #check if bypassed critical threshold
    if(opts["critical"])
      if(@info["Containers"].to_i > opts["critical"].to_i)
        @info["CRITICAL"]+="Current #{@info["Containers"]} container/s with a warning threshold of #{opts["critical"].to_i} "
      end
    end
    
    # if the @info hash contains any criticals or warning it enables returning different exit code
    @warning = @info.has_key?("WARNING")
    @critical = @info.has_key?("CRITICAL")
  end
  
  def perf_data
    pd="|"
    #generation of the perfomance data based on numeric results
    @info.each do |label,val|
      if (val.is_number?)
         pd+="#{label}=#{val.delete(' ')} ,"
      end
    end
    pd[0..-2]
  end

  def general_output
    gout=""
    #generation of the general output data based on non-numeric results
    @info.each do |label,val|
      if (!val.is_number?)
         gout+="#{label} is #{val.delete(' ')} ,"
      end
    end
    gout[0..-2]
  end
 
  def critical?
    @msg = @info["CRITICAL"] + perf_data if @info["CRITICAL"]
    @critical
  end

  def warning?
    @msg = @info["WARNING"] + perf_data  if @info["WARNING"]
    @warning 
  end

  def ok?
    @msg = general_output + perf_data
    @ok
  end
  
   
  def message
    @msg
  end
end

#call the script and print the result
DockerInfo.check
