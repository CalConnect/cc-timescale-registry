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


class AuthorityInfo {
  +authorityCode: String
  +uri: Uri
  +name: LocalizedStringCollection
  +iso3166Code: iso3166Code
  +description: LocalizedStringCollection
'  +publicKey: PublicKey
}

class OfficialAuthorityInfo extends AuthorityInfo {
}

class InternationalAuthorityInfo extends AuthorityInfo {
  +iso3166Code: iso3166Code = AA
}

class UnofficialAuthorityInfo extends AuthorityInfo {
  +iso3166Code: iso3166Code = ZZ
}

'class SignatureInfo {
'  +signature: String
'  +algorithm: iso14888Oid
'  +publicKeyUri: Uri
'}
'
'class PublicKey {
'  +algorithm: iso14888Oid
'  +content: String
'  +uri: Uri
'  +validity: ValidityInfo
'}

'class iso14888Oid <<dataType>>{
'
'}


'******* CLASS RELATIONS **********************************************

'SignatureInfo <-- iso14888Oid
'AuthorityInfo <-- PublicKey
@enduml
