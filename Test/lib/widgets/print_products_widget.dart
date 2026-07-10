import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/responsive.dart';
import 'common_widgets.dart';

class PrintProductsWidget extends StatelessWidget {
  const PrintProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(provider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => provider.fetchProducts(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Products to Print',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products first, then come back to print.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return _PrintProductsContent(
      products: products,
      isMobile: isMobile,
    );
  }
}

class _PrintProductsContent extends StatefulWidget {
  const _PrintProductsContent({required this.products, required this.isMobile});

  final List<Product> products;
  final bool isMobile;

  @override
  State<_PrintProductsContent> createState() => _PrintProductsContentState();
}

class _PrintProductsContentState extends State<_PrintProductsContent> {
  bool _isGenerating = false;

  Future<void> _printPdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _buildPdf(widget.products);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Product_Report_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _buildPdf(widget.products);
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Product_Report.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<pw.Document> _buildPdf(List<Product> products) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final font = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Product Report',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 22,
                  color: PdfColor.fromHex('#1565C0'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on: ${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Total Products: ${products.length}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColor.fromHex('#1565C0'), thickness: 1.5),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1565C0'),
              ),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 28,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA')),
              headers: ['#', 'Name', 'Price', 'Stock', 'Status', 'Created Date'],
              data: products.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final p = entry.value;
                return [
                  '$index',
                  p.name ?? '-',
                  '\$${p.price.toStringAsFixed(2)}',
                  '${p.stock}',
                  p.isActive ? 'Active' : 'Inactive',
                  '${p.createdDate.day}/${p.createdDate.month}/${p.createdDate.year}',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    final products = widget.products;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.print, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Print Preview — ${products.length} product${products.length == 1 ? '' : 's'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
              ),
              const Spacer(),
              ActionChipButton(
                label: _isGenerating ? 'Generating...' : 'Download PDF',
                icon: Icons.download,
                color: Colors.orange.shade700,
                onPressed: _isGenerating ? null : _downloadPdf,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _printPdf,
                icon: _isGenerating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.print, size: 18),
                label: const Text('Print'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.print, size: 28, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Report',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.blue.shade100, thickness: 2),
                    const SizedBox(height: 6),
                    Text(
                      'Total Products: ${products.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    _buildPreviewTable(isMobile, products),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTable(bool isMobile, List<Product> products) {
    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);
    final cellStyle = TextStyle(fontSize: 11, color: Colors.grey.shade800);

    return Table(
      columnWidths: {
        0: const FlexColumnWidth(0.5),
        1: const FlexColumnWidth(3),
        2: const FlexColumnWidth(1.5),
        3: const FlexColumnWidth(),
        4: const FlexColumnWidth(1.2),
        if (!isMobile) 5: const FlexColumnWidth(1.8),
      },
      border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1565C0)),
          children: [
            _headerCell('#', headerStyle),
            _headerCell('Name', headerStyle),
            _headerCell('Price', headerStyle),
            _headerCell('Stock', headerStyle),
            _headerCell('Status', headerStyle),
            if (!isMobile) _headerCell('Created Date', headerStyle),
          ],
        ),
        ...products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isOdd = i % 2 == 1;
          return TableRow(
            decoration: BoxDecoration(
              color: isOdd ? Colors.grey.shade50 : Colors.white,
            ),
            children: [
              _dataCell('${i + 1}', cellStyle, align: TextAlign.center),
              _dataCell(p.name ?? '-', cellStyle),
              _dataCell('\$${p.price.toStringAsFixed(2)}', cellStyle, align: TextAlign.right),
              _dataCell('${p.stock}', cellStyle, align: TextAlign.center),
              _statusCell(p.isActive),
              if (!isMobile)
                _dataCell(
                  '${p.createdDate.day}/${p.createdDate.month}/${p.createdDate.year}',
                  cellStyle,
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _headerCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(text, style: style),
    );
  }

  Widget _dataCell(String text, TextStyle style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(text, style: style, textAlign: align),
    );
  }

  Widget _statusCell(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}
