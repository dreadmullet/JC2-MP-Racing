
function CourseEditor:DefineCommands()
	
	local C = self.commands
	
	C.globalinfo = function(args)
		
		self:MessagePlayer(args.player , "World: "..self.worldId)
		self:MessagePlayer(
			args.player ,
			"Number of editors open: "..table.count(CourseEditor.globals.courseEditors)
		)
		
	end
	
	C.courseinfo = function(args)
		
		local Message = function(name , value)
			self:MessagePlayer(args.player , name..": "..value)
		end
		
		Message("Name" , self.course.name)
		Message("Checkpoints" , #self.course.checkpoints)
		
	end
	C.ci = C.courseinfo
	
	C.reload = function(args)
		
		Network:Send(args.player , "CEReplaceCourse" , self.course:Marshal())
		
	end
	
end
