import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReciboService {
  static Future<void> imprimirRecibo(Map<dynamic, dynamic> pagoRaw) async {
    final Map<String, dynamic> pago = pagoRaw.cast<String, dynamic>();
    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          final detalles = pago['detalles'] as List? ?? [];
          final vivienda = pago['vivienda'] ?? {};
          final socio = vivienda['socio'] ?? {};
          final periodo = pago['periodo'] ?? {};
          final rangos = pago['desgloce_rangos'] as List? ?? [];

          return pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('COMITÉ DE AGUA POTABLE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                ),
                pw.Center(child: pw.Text('SISTEMA DE CONTROL DE AGUA', style: const pw.TextStyle(fontSize: 10))),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1),
                pw.Center(child: pw.Text('RECIBO DE PAGO',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                pw.SizedBox(height: 10),
                
                pw.Text('Nro: ${pago['referencia'] ?? pago['id']}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Fecha: $date', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Periodo: ${periodo['nombre'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.SizedBox(height: 8),

                // Readings info
                if (vivienda['tipo_lectura'] == 'mensual' || vivienda['tipo_lectura'] == 'anual' || pago['lectura_actual'] != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('L. Anterior: ${pago['lectura_anterior'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('L. Actual: ${pago['lectura_actual'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Center(child: pw.Text('Consumo Total: ${pago['consumo'] ?? '0'} m3', 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 8),
                
                pw.Text('Socio: ${socio['name'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Código: ${vivienda['codigo'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Zona: ${vivienda['zona']?['name'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9)),
                
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Concepto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                // Detail of ranges if present
                if (rangos.isNotEmpty) ...[
                  ...rangos.map((r) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Rango: ${r['desde']}-${r['hasta'] ?? 'inf'} (${r['metros']}m3 x ${r['precio_metro']})', 
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('Bs. ${r['subtotal']}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  )),
                  pw.Divider(thickness: 0.1, color: PdfColors.grey400),
                ],

                ...detalles.map((d) {
                  String label = d['descripcion'] ?? d['tipo'] ?? 'Otro';
                  if (label.length > 25) label = label.substring(0, 22) + '...';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Bs. ${d['monto']}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  );
                }),

                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL PAGADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Bs. ${pago['monto_total']}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Center(child: pw.Text('¡Gracias por su pago!', style: const pw.TextStyle(fontSize: 8))),
                pw.Center(child: pw.Text('Cualquier reclamo presente este recibo.', style: const pw.TextStyle(fontSize: 7))),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.BarcodeWidget(
                    data: 'RECIBO-${pago['id']}-${pago['monto_total']}',
                    barcode: pw.Barcode.qrCode(),
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'recibo_${pago['id']}.pdf',
    );
  }

  static Future<void> imprimirReporteMensual(Map<String, dynamic> resumen) async {
    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('REPORTE MENSUAL DE RECAUDACIÓN',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.Text('Generado el: $date'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Concepto', 'Valor'],
                data: [
                  ['Total Recaudado (Mes)', 'Bs. ${resumen['monto_del_mes']}'],
                  ['Pagos Realizados', '${resumen['pagos_del_mes']}'],
                  ['Viviendas Pendientes', '${resumen['viviendas_pendientes']}'],
                  ['Total Viviendas', '${resumen['total_viviendas']}'],
                  ['Eficiencia de Cobro', '${((resumen['viviendas_pagadas'] / resumen['total_viviendas']) * 100).toStringAsFixed(1)}%'],
                ],
              ),
                pw.SizedBox(height: 40),
                pw.Center(child: pw.Text('Firma Responsable')),
                pw.Center(child: pw.Divider(thickness: 1, color: PdfColors.grey300)),
              ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'reporte_mensual.pdf',
    );
  }
}
