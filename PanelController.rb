# PanelController.rb
# Lyrics-in-Sight-MacRuby
#
# Created by Michel Steuwer on 23.04.10.
# Copyright 2010 __MyCompanyName__. All rights reserved.

require "AppController"
require "AbstractNotifier"
require "NotifierFactory"
require "FormulaParser"

class	PanelController < NSWindowController

	attr_reader :type
	attr_accessor :textView
	
	def initWithControllerAndType(controller, type)
		if initWithWindowNibName("Panel")
			@controller = controller
			
			setShouldCascadeWindows(false)
			@rect = NSMakeRect(500, 500, 500, 300)
			@type = type
			@formula = NSAttributedString.alloc.initWithString("Edit this text")
			@inEditMode = false
			
			@notifier = NotifierFactory.getNotifierForPanelController(self)
			@notifier.registerPanelController(self)
			self
		end
	end
	
	def initWithControllerAndDictionary(controller, dictionary)
		if initWithControllerAndType(controller, dictionary["Type"])
			@formula					= NSKeyedUnarchiver.unarchiveObjectWithData(dictionary["Formula"])
			@rect.origin.x		= dictionary["X"]
			@rect.origin.y		= dictionary["Y"]
			@rect.size.width	= dictionary["Width"]
			@rect.size.height	= dictionary["Height"]
			self
		end
	end
	
	def dictionary
		dictionary = Hash.new
		dictionary["Type"]		= @type
		dictionary["Formula"] = NSKeyedArchiver.archivedDataWithRootObject(@formula)
		dictionary["X"]				= @rect.origin.x
		dictionary["Y"]				= @rect.origin.y
		dictionary["Width"]		= @rect.size.width
		dictionary["Height"]	= @rect.size.height
		dictionary 
	end
	
	def update(userInfo)
		if @inEditMode
			return
		end
		
		if userInfo == nil
			@textView.setString("")
			return
		end
		
		parser = FormulaParser.alloc.initWithDictionary(userInfo)
		attributedString = parser.evaluateFormula(@formula)
		@textView.textStorage.setAttributedString(attributedString)
	end
	
	def editModeStarted
		@inEditMode = true
		
		setEditable(true)
		
		@textView.textStorage.setAttributedString(@formula)
	end
	
	def editModeStopped
		@inEditMode = false
		
		@formula = NSAttributedString.alloc.initWithAttributedString(@textView.textStorage) # copy attributed string back
		@rect = window.frame
		
		setEditable(false)
		
		@notifier.requestUpdate(self)
	end
	
	def setEditable(newState)
		window.setMovable(newState)
		if newState
			window.setStyleMask(window.styleMask | NSClosableWindowMask | NSResizableWindowMask | NSTitledWindowMask | NSUtilityWindowMask)
		else
			window.setStyleMask(window.styleMask & ~NSClosableWindowMask & ~NSResizableWindowMask & ~NSTitledWindowMask & ~NSUtilityWindowMask)
		end
		
		@textView.setEditable(newState)
		@textView.setSelectable(newState)
		if !newState
			@textView.updateInsertionPointStateAndRestartTimer(false)
		end
	end
	
	def windowDidLoad
		window.setLevel(CGWindowLevelForKey(KCGDesktopWindowLevelKey))
		window.setFrame(@rect, display: true, animate: true)
		setEditable(false)
		
		@notifier.requestUpdate(self)
		
		window.display
	end
	
	def windowWillClose(notification)
		@notifier.unregisterPanelController(self)
		@controller.removePanel(self)
	end
	
	def description
		"PanelController: type = '#{@type}', formula = '#{@formula.string}', x = #{rect.origin.x}, y = #{rect.origin.y}, width = #{rect.size.width}, height = #{rect.size.height}"
	end
	
end
