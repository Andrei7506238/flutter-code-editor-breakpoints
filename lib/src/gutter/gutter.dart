// TODO(alexeyinkin): Remove when dropping support for Flutter < 3.10, https://github.com/akvelon/flutter-code-editor/issues/245
// ignore_for_file: unnecessary_non_null_assertion

import 'package:flutter/material.dart';

import '../code_field/code_controller.dart';
import '../line_numbers/gutter_style.dart';
import 'error.dart';
import 'fold_toggle.dart';

const _breakpointsColumnWidth = 16.0;
const _issueColumnWidth = 16.0;
const _foldingColumnWidth = 16.0;

const _breakpointsColumn = 0;
const _lineNumberColumn = 1;
const _issueColumn = 2;
const _foldingColumn = 3;

class GutterWidget extends StatelessWidget {
  const GutterWidget({
    required this.codeController,
    required this.style,
  });

  final CodeController codeController;
  final GutterStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: codeController,
      builder: _buildOnChange,
    );
  }

  Widget _buildOnChange(BuildContext context, Widget? child) {
    final code = codeController.code;

    final gutterWidth = style.width -
        (style.showErrors ? 0 : _issueColumnWidth) -
        (style.showFoldingHandles ? 0 : _foldingColumnWidth) -
        (style.showBreakpoints ? 0 : _breakpointsColumnWidth);

    final issueColumnWidth = style.showErrors ? _issueColumnWidth : 0.0;
    final foldingColumnWidth = style.showFoldingHandles ? _foldingColumnWidth : 0.0;

    final breakpointsColumnWidth = style.showBreakpoints ? _breakpointsColumnWidth : 0.0;

    final tableRows = List.generate(
      code.hiddenLineRanges.visibleLineNumbers.length,
      // ignore: prefer_const_constructors
      (i) => TableRow(
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
        ],
      ),
    );

    _fillLineNumbers(tableRows);

    if (style.showErrors) {
      _fillIssues(tableRows);
    }
    if (style.showFoldingHandles) {
      _fillFoldToggles(tableRows);
    }
    if (style.showBreakpoints) {
      _fillBreakpoints(tableRows);
    }

    return Container(
      padding: EdgeInsets.only(top: 12, bottom: 12, right: style.margin),
      width: style.showLineNumbers ? gutterWidth : null,
      child: Table(
        columnWidths: {
          _breakpointsColumn: FixedColumnWidth(breakpointsColumnWidth),
          _lineNumberColumn: const FlexColumnWidth(),
          _issueColumn: FixedColumnWidth(issueColumnWidth),
          _foldingColumn: FixedColumnWidth(foldingColumnWidth),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: tableRows,
      ),
    );
  }

  void _fillLineNumbers(List<TableRow> tableRows) {
    final code = codeController.code;

    for (final i in code.hiddenLineRanges.visibleLineNumbers) {
      final lineIndex = _lineIndexToTableRowIndex(i);

      if (lineIndex == null) {
        continue;
      }

      tableRows[lineIndex].children![_lineNumberColumn] = Text(
        style.showLineNumbers ? '${i + 1}' : ' ',
        style: style.textStyle,
        textAlign: style.textAlign,
      );
    }
  }

  void _fillIssues(List<TableRow> tableRows) {
    for (final issue in codeController.analysisResult.issues) {
      if (issue.line >= codeController.code.lines.length) {
        continue;
      }

      final lineIndex = _lineIndexToTableRowIndex(issue.line);
      if (lineIndex == null || lineIndex >= tableRows.length) {
        continue;
      }
      tableRows[lineIndex].children![_issueColumn] = GutterErrorWidget(
        issue,
        style.errorPopupTextStyle ?? (throw Exception('Error popup style should never be null')),
      );
    }
  }

  void _fillBreakpoints(List<TableRow> tableRows) {
    for (int i = 0; i < codeController.code.lines.length; i++) {
      final lineIndex = _lineIndexToTableRowIndex(i);
      if (lineIndex == null || lineIndex >= tableRows.length) {
        continue;
      }

      final isBreakpoint = codeController.breakpoints.contains(i);
      tableRows[lineIndex].children![_breakpointsColumn] = BreakpointWidget(
        isBreakpoint: isBreakpoint,
        onTap: () => codeController.onToggleBreakpoint?.call(i),
      );
    }
  }

  void _fillFoldToggles(List<TableRow> tableRows) {
    final code = codeController.code;

    for (final block in code.foldableBlocks) {
      final lineIndex = _lineIndexToTableRowIndex(block.firstLine);
      if (lineIndex == null) {
        continue;
      }

      final isFolded = code.foldedBlocks.contains(block);

      tableRows[lineIndex].children![_foldingColumn] = FoldToggle(
        color: style.textStyle?.color,
        isFolded: isFolded,
        onTap: isFolded ? () => codeController.unfoldAt(block.firstLine) : () => codeController.foldAt(block.firstLine),
      );
    }

    // Add folded blocks that are not considered as a valid foldable block,
    // but should be folded because they were folded before becoming invalid.
    for (final block in code.foldedBlocks) {
      final lineIndex = _lineIndexToTableRowIndex(block.firstLine);
      if (lineIndex == null || lineIndex >= tableRows.length) {
        continue;
      }

      tableRows[lineIndex].children![_foldingColumn] = FoldToggle(
        color: style.textStyle?.color,
        isFolded: true,
        onTap: () => codeController.unfoldAt(block.firstLine),
      );
    }
  }

  int? _lineIndexToTableRowIndex(int line) {
    return codeController.code.hiddenLineRanges.cutLineIndexIfVisible(line);
  }
}

class BreakpointWidget extends StatelessWidget {
  final bool isBreakpoint;
  final VoidCallback? onTap;

  const BreakpointWidget({
    super.key,
    required this.isBreakpoint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: _breakpointsColumnWidth / 2,
          backgroundColor: isBreakpoint ? Colors.red : Colors.transparent,
          child: isBreakpoint
              ? Icon(
                  Icons.circle,
                  color: Colors.red.shade400,
                  size: _breakpointsColumnWidth - 4,
                )
              : null,
        ),
      ),
    );
  }
}
