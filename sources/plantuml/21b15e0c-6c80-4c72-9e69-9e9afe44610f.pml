@startuml

skinparam Dpi 150
skinparam Monochrome false
skinparam LineType ortho
hide circle
/' skinparam CircledCharacterRadius 0 '/
/' skinparam CircledCharacterFontSize 0 '/
skinparam Default {
  TextAlignment center
  FontName Helvetica
}
skinparam Class {
  AttributeIconSize 0
  BackgroundColor White
  ArrowColor Black
  BorderColor Black
  FontStyle bold
  StereotypeFontSize 10
}
skinparam Rectangle {
  BackgroundColor White
  ArrowColor Black
  BorderColor Black
  FontStyle bold
  FontSize 11
  StereotypeFontSize 10
}
skinparam Object {
  BackgroundColor White
  ArrowColor Black
  BorderColor Black
  FontStyle bold
  FontSize 11
  StereotypeFontSize 10
}

skinparam Entity {
  StereotypeFontSize 10
}


/' vim:set ft=plantuml: '/
'******* CLASS DEFINITION *********************************************

class ReferenceTimeScale {
  +id: Uid
  +authority: AuthorityInfo
  +name: LocalizedStringCollection
  +description: LocalizedStringCollection
' +leapSeconds: LeapSecondRecord[0..*]
}

'class LeapSecondRecord {
'  +time: iso8601DateTime
'  +seconds: Integer
'}

'******* NOTES ********************************************************

'ReferenceTimeScale <|-down- LeapSecondRecord
@enduml
