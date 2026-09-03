Function CreateFontManager() as Object
    Print "FontManager : CreateFontManager"

    dmSansRegular = "pkg:/Fonts/DMSans-Regular.ttf"
    dmSansMedium = "pkg:/Fonts/DMSans-Medium.ttf"
    dmSansBold = "pkg:/Fonts/DMSans-Bold.ttf"

    this = {}
    ' *** DM Sans Bold Fonts ***
    this.dmSansBold48 = CreateFonts(dmSansBold, 48)
    this.dmSansBold36 = CreateFonts(dmSansBold, 36)
    this.dmSansBold32 = CreateFonts(dmSansBold, 32)
    this.dmSansBold30 = CreateFonts(dmSansBold, 30)
    this.dmSansBold28 = CreateFonts(dmSansBold, 28)
    this.dmSansBold23 = CreateFonts(dmSansBold, 23)
    this.dmSansBold20 = CreateFonts(dmSansBold, 20)
    this.dmSansBold18 = CreateFonts(dmSansBold, 18)

    ' *** DM Sans Medium Fonts ***
    this.dmSansMedium12 = CreateFonts(dmSansMedium, 12)
    this.dmSansMedium14 = CreateFonts(dmSansMedium, 14)
    this.dmSansMedium18 = CreateFonts(dmSansMedium, 18)
    this.dmSansMedium19 = CreateFonts(dmSansMedium, 19)
    this.dmSansMedium20 = CreateFonts(dmSansMedium, 20)
    this.dmSansMedium23 = CreateFonts(dmSansMedium, 23)
    this.dmSansMedium24 = CreateFonts(dmSansMedium, 24)
    this.dmSansMedium25 = CreateFonts(dmSansMedium, 25)
    this.dmSansMedium26 = CreateFonts(dmSansMedium, 26)
    this.dmSansMedium29 = CreateFonts(dmSansMedium, 29)
    this.dmSansMedium30 = CreateFonts(dmSansMedium, 30)
    this.dmSansMedium31 = CreateFonts(dmSansMedium, 31)
    this.dmSansMedium32 = CreateFonts(dmSansMedium, 32)
    this.dmSansMedium37 = CreateFonts(dmSansMedium, 37)
    this.dmSansMedium39 = CreateFonts(dmSansMedium, 39)

    ' *** DM Sans Regular Fonts ***
    this.dmSansReg53 = CreateFonts(dmSansRegular, 53)
    this.dmSansReg42 = CreateFonts(dmSansRegular, 42)
    this.dmSansReg35 = CreateFonts(dmSansRegular, 35)
    this.dmSansReg26 = CreateFonts(dmSansRegular, 26)

    node = CreateObject("roSGNode", "node")
    node.AddFields(this)
    Return node
End Function

Function CreateFonts(uri as String, size as Integer) as Dynamic
    font = CreateObject("roSGNode", "Font")
    font.uri = uri
    font.size = size
    Return font
End Function
