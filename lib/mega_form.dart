// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pad5/pad5.dart';

class MegaForm extends StatelessWidget {
  MegaForm({
    required this.controller,
    required this.child,
    this.onChanged,
  }):
    formKey = controller.formKey;

  final GlobalKey<FormBuilderState> formKey;

  final MegaFormController controller;
  final Widget child;
  final void Function(Map<String, dynamic>)? onChanged;

  static FormFieldValidator<T> required<T>() => FormBuilderValidators.required<T>(errorText: 'Required');

  Map<String, dynamic>? onSave(bool validate) {
    var state = formKey.currentState;
    if(state == null)
      return null;
    if(validate && !state.validate())
      return null;
    var json = state.fields.map((key, field) {
      return MapEntry(key, field.transformedValue);
    });
    return json;
  }

  @override
  Widget build(context) {
    controller._onSave = onSave;
    return FormBuilder(
      key: formKey,
      autovalidateMode: AutovalidateMode.always,
      child: child,
      onChanged: () {
        if(onChanged == null)
          return;
        var state = controller.save(false);
        if(state != null)
          onChanged!(state);
      },
    );
  }
}

class MegaFormController {
  MegaFormController();

  final formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic>? Function(bool validate)? _onSave;

  Map<String, dynamic>? save([bool validate = true]) {
    var json = _onSave?.call(validate);
    return json;
  }
}

class MegaFormSettingsGroup extends StatelessWidget {
  const MegaFormSettingsGroup({
    required this.title,
    required this.fields,
  });

  final String title;
  final List<Widget> fields;

  @override
  Widget build(context) {
    return Column(
      children:[
        Row(
          children: [
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ).padAll,
              ),
            ),
          ],
        ),
        ...fields,
      ],
    );
  }
}

abstract class MegaFormField extends StatelessWidget {
  const MegaFormField();
}

class MegaFormSettingContainer extends MegaFormField {
  const MegaFormSettingContainer({
    required this.label,
    this.help,
    required this.child,
    this.vertical = false,
    this.afterLabelBuilder,
  });

  final String label;
  final String? help;
  final Widget child;
  final Widget Function()? afterLabelBuilder;
  final bool vertical;

  @override
  Widget build(context) {
    var help_ = help ?? '';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if(help_.isNotEmpty)
                        Tooltip(
                          richMessage: TextSpan(
                            children: [
                              TextSpan(
                                text: '$label\n',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onInverseSurface,
                                ),
                              ),
                              TextSpan(text: help_),
                            ],
                          ),
                          preferBelow: true,
                          enableTapToDismiss: true,
                          exitDuration: null,
                          showDuration: const Duration(days: 1),
                          triggerMode: TooltipTriggerMode.tap,
                          child: const Icon(Icons.help),
                        )
                      else
                        const SizedBox.shrink(),
                      if(afterLabelBuilder != null)
                        afterLabelBuilder!()
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
            if(!vertical)
              Pad.horizontalSpace,
            if(!vertical)
              Expanded(
                child: child,
              ),
          ],
        ),
        if(vertical)
          child,
        const Divider(),
      ],
    ).padHorizontal;
  }
}

class MegaFormFieldString extends MegaFormField {
  const MegaFormFieldString({
    required this.name,
    required this.label,
    this.help,
    this.isEnabled = true,
    required this.initialValue,
    this.isRequired = true,
    this.maxLen = 0,
    this.afterLabelBuilder,
  });

  final String name;
  final String label;
  final String? help;
  final bool isEnabled;
  final String initialValue;
  final bool isRequired;
  final int maxLen;
  final Widget Function(String fieldName)? afterLabelBuilder;

  @override
  Widget build(context) {
    return MegaFormSettingContainer(
      label: label,
      help: help,
      afterLabelBuilder: afterLabelBuilder == null ? null : () => afterLabelBuilder!(name),
      child: FormBuilderTextField(
        name: name,
        initialValue: initialValue,
        enabled: isEnabled,
        valueTransformer: (s) => s?.trim(),
        validator: FormBuilderValidators.compose([
          if(isRequired)
            MegaForm.required(),
          if(maxLen > 0)
            FormBuilderValidators.maxLength(maxLen, errorText: '$maxLen symbols max', checkNullOrEmpty: false),
        ]),
      ),
    );
  }
}

class MegaFormFieldNum<T extends num> extends MegaFormField {
  const MegaFormFieldNum({
    required this.typeName,
    required this.name,
    required this.label,
    this.help,
    this.isEnabled = true,
    required this.initialValue,
    this.afterLabelBuilder,
    this.isRequired = true,
    this.min,
    this.minInclusive = true,
    this.max,
    this.maxInclusive = false,
  });

  final String typeName;
  final String name;
  final String label;
  final String? help;
  final bool isEnabled;
  final num initialValue;
  final bool isRequired;
  final T? min;
  final bool minInclusive;
  final T? max;
  final bool maxInclusive;
  final Widget Function(String fieldName)? afterLabelBuilder;

  @override
  Widget build(context) {
    return MegaFormSettingContainer(
      label: label,
      help: help,
      afterLabelBuilder: afterLabelBuilder == null ? null : () => afterLabelBuilder!(name),
      child: FormBuilderTextField(
        name: name,
        enabled: isEnabled,
        initialValue: initialValue.toString(),
        valueTransformer: (s) => num.tryParse(s?.trim() ?? '') ?? initialValue,
        validator: FormBuilderValidators.compose([
          if(isRequired)
            MegaForm.required(),
          FormBuilderValidators.float(errorText: 'Must be a valid $typeName', checkNullOrEmpty: false),
          if(min != null)
            FormBuilderValidators.min(
              min!,
              inclusive: minInclusive,
              errorText: minInclusive ? 'Min. value: $min' : 'Must be greater than $min',
              checkNullOrEmpty: false,
            ),
          if(max != null)
            FormBuilderValidators.max(
              max!,
              inclusive: maxInclusive,
              errorText: maxInclusive ? 'Max. value: $max' : 'Must be lower than $max',
              checkNullOrEmpty: false,
            ),
        ]),
      ),
    );
  }
}

class MegaFormFieldBool extends MegaFormField {
  const MegaFormFieldBool({
    required this.name,
    required this.label,
    this.help,
    this.isEnabled = true,
    required this.initialValue,
    this.afterLabelBuilder,
  });

  final String name;
  final String label;
  final String? help;
  final bool isEnabled;
  final bool initialValue;
  final Widget Function(String fieldName)? afterLabelBuilder;

  @override
  Widget build(context) {
    return MegaFormSettingContainer(
      label: label,
      help: help,
      afterLabelBuilder: afterLabelBuilder == null ? null : () => afterLabelBuilder!(name),
      child: FormBuilderCheckbox(
        name: name,
        title: const SizedBox.shrink(),
        enabled: isEnabled,
        initialValue: initialValue,
        valueTransformer: (x) => x ?? initialValue,
      ),
    );
  }
}

class MegaFormFieldDropdown<T> extends MegaFormField {
  const MegaFormFieldDropdown({
    required this.name,
    required this.label,
    this.help,
    this.isEnabled = true,
    required this.items,
    required this.initialValue,
    this.afterLabelBuilder,
    this.vertical = false,
  });

  final String name;
  final String label;
  final String? help;
  final bool isEnabled;
  final List<DropdownMenuItem<T>> items;
  final T initialValue;
  final Widget Function(String fieldName)? afterLabelBuilder;
  final bool vertical;

  @override
  Widget build(context) {
    return MegaFormSettingContainer(
      label: label,
      help: help,
      afterLabelBuilder: afterLabelBuilder == null ? null : () => afterLabelBuilder!(name),
      vertical: vertical,
      child: FormBuilderDropdown(
        name: name,
        enabled: isEnabled,
        items: items,
        initialValue: initialValue,
        isDense: false,
        valueTransformer: (x) => x ?? initialValue,
      ),
    );
  }
}

class MegaFormFieldStringListChip extends MegaFormField {
  const MegaFormFieldStringListChip({
    required this.name,
    required this.label,
    this.help,
    this.isEnabled = true,
    required this.initialValue,
    required this.options,
    this.backgroundColor,
    this.selectedColor,
    this.afterLabelBuilder,
  });

  final String name;
  final String label;
  final String? help;
  final bool isEnabled;
  final List<String> initialValue;
  final List<FormBuilderChipOption> options;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Widget Function(String fieldName)? afterLabelBuilder;

  @override
  Widget build(context) {
    return MegaFormSettingContainer(
      label: label,
      help: help,
      vertical: true,
      afterLabelBuilder: afterLabelBuilder == null ? null : () => afterLabelBuilder!(name),
      child: FormBuilderFilterChips(
        name: name,
        enabled: isEnabled,
        initialValue: initialValue,
        backgroundColor: backgroundColor,
        selectedColor: selectedColor,
        spacing: Pad.pad,
        showCheckmark: false,
        options: options,
      ),
    );
  }
}
