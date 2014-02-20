require 'redis'
require 'singleton'

require 'net/https'
require 'uri'
require 'date'

require './lib/models'
require './lib/websockets'
require './lib/chatserver'

## Thanks http://soohwan.blogspot.de/2011/02/fix-eventmachineperiodictimer.html
module EventMachine  
 class PeriodicTimer  
   alias :old_initialize :initialize  
   def initialize interval, callback=nil, &block  
     # Added two additional instance variables to compensate difference.   
     @start = Time.now  
     @fixed_interval = interval  
     old_initialize interval, callback, &block  
   end  
   alias :old_schedule :schedule  
   def schedule  
     # print "Started at #{@start}..: "  
     compensation = (Time.now - @start) % @fixed_interval   
     @interval = @fixed_interval - compensation  
     # Schedule   
     old_schedule  
   end  
 end  
end 
