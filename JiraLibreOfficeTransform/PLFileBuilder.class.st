Class {
	#name : #PLFileBuilder,
	#superclass : #Object,
	#instVars : [
		'columnsForFile',
		'columnsForDays',
		'days',
		'field',
		'fileContent',
		'resources',
		'columnsForPredecessors'
	],
	#category : #JiraLibreOfficeTransform
}

{ #category : #building }
PLFileBuilder >> buildContentFromFileName: fileName [

	|fileRef header columnKeys predecessorKeys issueIdKey dayKeys forecastKeys |
	
	fileRef := fileName asFileReference. 
	header := self headerFrom: fileRef. 
	columnKeys := self keysFromHeader: header forColumns: self columnsForFile. 
	dayKeys := self keysFromHeader: header forDays: self columnsForDays. 
	predecessorKeys := self predecessorkeysFromHeader: header.
	issueIdKey := self issueIdKeyFromHeader: header.
	forecastKeys := self keysFromHeader: header forForecast: self columnsForForecast. 
	self buildFrom: fileRef columnKeys: columnKeys issueKey: issueIdKey predecessorKeys: predecessorKeys dayKeys: dayKeys forecastKeys: forecastKeys.
	 

]

{ #category : #building }
PLFileBuilder >> buildFrom: fileRef columnKeys: colKeys issueKey: issueKey predecessorKeys: predecessorKeys dayKeys: dayKeys forecastKeys: forecastKeys [

	| file basicRow colData calculatedDays forecast |

	file := self contentsFrom: fileRef.
	file allButFirstDo: [ :row |

		basicRow := OrderedCollection new. 
		forecast := 0.
		colKeys do: [ :colKey | 

			colData := (row at: colKey).

			(dayKeys includes: colKey) ifTrue: [  
				calculatedDays := 0.
				colData ifNotNil: [  
					calculatedDays := (Float readFrom: colData) / 28800.
				].
				basicRow add: calculatedDays.
				(forecastKeys includes: colKey) ifTrue: [  
					forecast := forecast + calculatedDays 		
				]
			]
			ifFalse: [  
				colData ifNil: [
					colData := ''	
				]. 					
				basicRow add: (colData copyReplaceAll: ',' with: '-') 					
			]
		].
		basicRow add: forecast printString. 
		basicRow add: (self predecessorListFromRow: row predecessorKeys: predecessorKeys). 
		self fileContent at: (row at: issueKey) put: basicRow
	].
	
]

{ #category : #building }
PLFileBuilder >> columnForIssueId [

	^ #'Issue key' 
]

{ #category : #building }
PLFileBuilder >> columnsForDays [

	^ columnsForDays ifNil: [
				
		columnsForDays := #(
			#'Original Estimate' 
			#'Remaining Estimate' 
			#'Time Spent' 
		)
	]

	
]

{ #category : #building }
PLFileBuilder >> columnsForFile [

	^ columnsForFile ifNil: [
				
		columnsForFile := #(
			#'Issue key' 
			#Summary 
			#'Issue Type' 
			#Status
			#Assignee
			#'Original Estimate' 
			#'Time Spent' 
			#'Remaining Estimate' 
			#'Custom field (Epic Link)' 
			#'Custom field (Target start)' 
			#'Custom field (Target end)' 
		)
	]

	
]

{ #category : #building }
PLFileBuilder >> columnsForForecast [

	^ columnsForDays ifNil: [
				
		columnsForDays := #(
			#'Time Spent' 
			#'Remaining Estimate' 
		)
	]

	
]

{ #category : #building }
PLFileBuilder >> columnsForPredecessors [

	^ columnsForPredecessors ifNil: [
				
		columnsForPredecessors := #(
			#'Inward issue link (Blocks)' 
			#'Inward issue link (Encompasses)' 
			#'Inward issue link (Relates)' 
		)
	]

]

{ #category : #building }
PLFileBuilder >> contentsFrom: fileRef [

	^ fileRef readStreamDo: [ :readStream | (NeoCSVReader on: readStream) upToEnd ].
]

{ #category : #building }
PLFileBuilder >> fileContent [

	^ fileContent ifNil: [ fileContent := OrderedDictionary new ]

]

{ #category : #building }
PLFileBuilder >> getRowsFrom: stringOfNumbers [

	| alphas |
	alphas := stringOfNumbers substrings: ';'.
	^ alphas collect: [ :a | a asInteger ] 
	

	
	
	
	



]

{ #category : #building }
PLFileBuilder >> headerFrom: fileRef [

	^ (NeoCSVReader on: fileRef readStream) readHeader collect: #asSymbol.
	
]

{ #category : #building }
PLFileBuilder >> issueIdKeyFromHeader: header [

	^ header indexOf: self columnForIssueId 
]

{ #category : #building }
PLFileBuilder >> keysFromHeader: header forColumns: columns [

	^ columns collect: [ :col |
		header indexOf: col
	]
]

{ #category : #building }
PLFileBuilder >> keysFromHeader: header forDays: columns [

	^ columns collect: [ :col |
		header indexOf: col
	]
]

{ #category : #building }
PLFileBuilder >> keysFromHeader: header forForecast: columns [

	^ columns collect: [ :col |
		header indexOf: col
	]
]

{ #category : #building }
PLFileBuilder >> linkFileContent [

	| issues predecessorString content|

	content := self fileContent. 
	content keysAndValuesDo: [ :key :value |
	
		predecessorString := ''.
		issues := value last substrings: ','.

		issues do: [ :issue |  
			(content includesKey: issue) ifTrue: [
				predecessorString := predecessorString, ';', (content indexOfKey: issue) printString	
			]
		].
		predecessorString ifNotEmpty: [  
			predecessorString := predecessorString allButFirst 
		].
		value atLast: 1 put: predecessorString
	]
]

{ #category : #building }
PLFileBuilder >> predecessorListFromRow: row predecessorKeys: predecessorKeys [

	| predecessorString issueId|
	
	predecessorString := ''.
	predecessorKeys do: [ :key | 
	
		issueId := row at: key.
		issueId ifNotNil: [  
			predecessorString := predecessorString, ',', issueId	
		]
	].

	predecessorString ifNotEmpty: [  
		predecessorString := predecessorString allButFirst 
	].
	^ predecessorString 
	
]

{ #category : #building }
PLFileBuilder >> predecessorkeysFromHeader: header [

	| predecessorKeys|
	predecessorKeys := Set new.
	
	1 to: header size do: [:index | 
		self columnsForPredecessors do: [ :col | 
			(header at: index) = col ifTrue: [
				predecessorKeys add: index  
			]	
		]
	].
		  
	^ predecessorKeys asArray 
]

{ #category : #building }
PLFileBuilder >> removeRedundantKey: rowsWithSortableKey [

	rowsWithSortableKey do: [ :row | 
		row removeFirst 
	]

]

{ #category : #building }
PLFileBuilder >> rowsWithSortableKey [

	| rows biggest rowNums newRow newRows offset newRowKey |

	newRows := OrderedCollection new.
	offset := 100000.

	rows := self fileContent values.

	1 to: rows size do: [ :index |

		newRow := (rows at: index) asOrderedCollection. 

		rowNums := self getRowsFrom: newRow last.
		biggest := 0.
		rowNums ifNotEmpty: [  
			biggest := rowNums max.
		].
		
		biggest = 0 ifTrue: [  
			newRowKey := index * offset
		] 
		ifFalse: [  
			newRowKey := (biggest* offset) + index
		].
		
		newRow addFirst: newRowKey.
		newRows add: newRow.
	
	].
	^ newRows
	

	
	
	
	



]

{ #category : #building }
PLFileBuilder >> sort [

	| rowsWithSortableKey |
	rowsWithSortableKey := self rowsWithSortableKey.
	
	self updatePredesessors: rowsWithSortableKey.
	self sortRows: rowsWithSortableKey.
	self transmogrifyRowNums: rowsWithSortableKey. 	
	self removeRedundantKey: rowsWithSortableKey.

	^ rowsWithSortableKey



]

{ #category : #building }
PLFileBuilder >> sortRows: rowsWithSortableKey [

	rowsWithSortableKey sort: [ :a :b | b first > a first]

]

{ #category : #building }
PLFileBuilder >> transmogrifyRowNums: rowsWithSortableKey [

	| successors newSuccessors |
	rowsWithSortableKey do: [ :row | 
		
		newSuccessors := ''.
		successors := self getRowsFrom: row last.
	
		successors do: [ :successor | 
			(1 to: rowsWithSortableKey size) do: [ :index | 
				((rowsWithSortableKey at: index) first = successor) ifTrue: [  
					newSuccessors := newSuccessors, ';', index printString
				]
			]			
		].
		newSuccessors ifNotEmpty: [  
			newSuccessors := newSuccessors allButFirst	
		].
		row atLast: 1 put: newSuccessors.
	]

]

{ #category : #building }
PLFileBuilder >> updatePredesessors: rowsWithSortableKey [

	| predesessors newRowKey keyString |
	rowsWithSortableKey do: [ :row | 
		
		keyString := ''.
		predesessors := self getRowsFrom: row last.
		
		predesessors do: [ :predesessor |
			newRowKey := rowsWithSortableKey at: predesessor. 
			keyString := keyString, ';', newRowKey first printString. 
		].
		keyString ifNotEmpty: [  
			keyString := keyString allButFirst 
		].
		row atLast: 1 put: keyString.
	]	
	 



]

{ #category : #building }
PLFileBuilder >> writeFileContentTo: fileName [

	| stream contentString writeableRows |

	self linkFileContent. 
	writeableRows := self sort.

	stream := fileName asFileReference writeStream.
	
	writeableRows do: [ :row |

		contentString := ''.		
		row do: [ :f |
			contentString := contentString, ',', f printString
		].
		contentString := contentString allButFirst copyReplaceAll: '''' with: ''.
		stream nextPutAll: contentString; cr  
	].
	stream flush
	
	
	



]
