import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfThemeColors {
  static const PdfColor primary = PdfColor.fromInt(0xFF183C35);
  static const PdfColor accent = PdfColor.fromInt(0xFFC89B5E);
  static const PdfColor background = PdfColor.fromInt(0xFFF7F8F8);
  static const PdfColor body = PdfColor.fromInt(0xFF4E4E4E);
  static const PdfColor heading = PdfColor.fromInt(0xFF183C35);
  static const PdfColor lightText = PdfColor.fromInt(0xFF888888);
  static const PdfColor tableHeader = PdfColor.fromInt(0xFF21463F);
  static const PdfColor tableBorder = PdfColor.fromInt(0xFFD7D7D7);
}

class PdfFontSizes {
  static const double title = 26;
  static const double subtitle = 14;
  static const double section = 14;
  static const double body = 11;
  static const double table = 10;
}

class PdfTextStyles {
  static pw.TextStyle reportTitle() {
    return pw.TextStyle(
      fontSize: PdfFontSizes.title,
      fontWeight: pw.FontWeight.bold,
      color: PdfThemeColors.primary,
    );
  }

  static pw.TextStyle reportSubtitle() {
    return pw.TextStyle(
      fontSize: PdfFontSizes.subtitle,
      fontWeight: pw.FontWeight.bold,
      color: PdfThemeColors.accent,
    );
  }

  static pw.TextStyle sectionTitle() {
    return pw.TextStyle(
      fontSize: PdfFontSizes.section,
      fontWeight: pw.FontWeight.bold,
      color: PdfThemeColors.heading,
    );
  }

  static pw.TextStyle body() {
    return pw.TextStyle(
      fontSize: PdfFontSizes.body,
      color: PdfThemeColors.body,
    );
  }

  static pw.TextStyle caption() {
    return pw.TextStyle(
      fontSize: PdfFontSizes.body,
      color: PdfThemeColors.lightText,
    );
  }

  static pw.TextStyle roomHeading() {
    return pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: PdfThemeColors.primary,
    );
  }
}

pw.Widget styledTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfThemeColors.tableBorder),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: PdfFontSizes.table,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfThemeColors.tableHeader),
      cellStyle: pw.TextStyle(
        fontSize: PdfFontSizes.table,
        color: PdfThemeColors.body,
      ),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      rowDecoration: const pw.BoxDecoration(color: PdfThemeColors.background),
      border: pw.TableBorder.all(width: 0, color: PdfColors.white),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        for (var i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
      },
    ),
  );
}
