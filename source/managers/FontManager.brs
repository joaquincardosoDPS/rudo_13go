Function CreateFontManager() as Object
    Print "FontManager : CreateFontManager"

    poppinsRegular = "pkg:/Fonts/Poppins-Regular.ttf"
    poppinsMedium = "pkg:/Fonts/Poppins-Medium.ttf"
    poppinsBold = "pkg:/Fonts/Poppins-Bold.ttf"

    this = {}
    ' *** Poppins Bold Fonts ***
    this.poppinsBold48 = CreateFonts(poppinsBold, 48)
    this.poppinsBold36 = CreateFonts(poppinsBold, 36)
    this.poppinsBold32 = CreateFonts(poppinsBold, 32)
    this.poppinsBold30 = CreateFonts(poppinsBold, 30)
    this.poppinsBold28 = CreateFonts(poppinsBold, 28)
    this.poppinsBold23 = CreateFonts(poppinsBold, 23)
    this.poppinsBold20 = CreateFonts(poppinsBold, 20)
    this.poppinsBold18 = CreateFonts(poppinsBold, 18)

    ' *** Poppins Medium Fonts ***
    this.poppinsMedium12 = CreateFonts(poppinsMedium, 12)
    this.poppinsMedium14 = CreateFonts(poppinsMedium, 14)
    this.poppinsMedium18 = CreateFonts(poppinsMedium, 18)
    this.poppinsMedium19 = CreateFonts(poppinsMedium, 19)
    this.poppinsMedium20 = CreateFonts(poppinsMedium, 20)
    this.poppinsMedium23 = CreateFonts(poppinsMedium, 23)
    this.poppinsMedium24 = CreateFonts(poppinsMedium, 24)
    this.poppinsMedium25 = CreateFonts(poppinsMedium, 25)
    this.poppinsMedium26 = CreateFonts(poppinsMedium, 26)
    this.poppinsMedium29 = CreateFonts(poppinsMedium, 29)
    this.poppinsMedium30 = CreateFonts(poppinsMedium, 30)
    this.poppinsMedium31 = CreateFonts(poppinsMedium, 31)
    this.poppinsMedium32 = CreateFonts(poppinsMedium, 32)
    this.poppinsMedium37 = CreateFonts(poppinsMedium, 37)
    this.poppinsMedium39 = CreateFonts(poppinsMedium, 39)

    ' *** Poppins Regular Fonts ***
    this.poppinsReg53 = CreateFonts(poppinsRegular, 53)
    this.poppinsReg42 = CreateFonts(poppinsRegular, 42)
    this.poppinsReg35 = CreateFonts(poppinsRegular, 35)
    this.poppinsReg26 = CreateFonts(poppinsRegular, 26)

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
