"
Usage:

PLBrowser new openWithSpec
"
Class {
	#name : #PLBrowser,
	#superclass : #SpPresenter,
	#instVars : [
		'buttonRead',
		'buttonWrite',
		'fileBuilder'
	],
	#category : #JiraLibreOfficeTransform
}

{ #category : #specs }
PLBrowser class >> defaultSpec [
	^ SpBoxLayout newTopToBottom
		add: #buttonRead;
		add: #buttonWrite;
		yourself
]

{ #category : #initialization }
PLBrowser >> fileBuilder [

	^ fileBuilder ifNil: [ fileBuilder := PLFileBuilder new ]

	
	
 

]

{ #category : #initialization }
PLBrowser >> initializePresenters [

	buttonRead := self newButton. 
	buttonWrite := self newButton. 
	
	buttonRead label: 'Add a file'; action: [ self readFile ].
	buttonWrite label: 'Write output'; action: [ self writeFile ].
	
	self focusOrder add: buttonRead; add: buttonWrite 
	

]

{ #category : #initialization }
PLBrowser >> readFile [

	| reference |
	reference := UIManager default chooseFullFileNameMatching: #('*.csv'). 

	reference ifNotNil: [
		reference asFileReference isFile ifTrue: [  
			self fileBuilder buildContentFromFileName: reference			
		]	
	]
 

]

{ #category : #initialization }
PLBrowser >> title [
	
	^ 'Jira to Project'.

]

{ #category : #initialization }
PLBrowser >> writeFile [

	self fileBuilder writeFileContentTo: '/home/jeff/Downloads/jira-', DateAndTime now asSeconds printString, '.csv'.	 
	fileBuilder := nil.
 

]
