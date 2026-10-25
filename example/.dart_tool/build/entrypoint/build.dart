// @dart=3.6
// ignore_for_file: type=lint
// build_runner >=2.4.16
import 'dart:io' as _io;
import 'package:build_runner/src/build_plan/builder_factories.dart'
    as _build_runner;
import 'package:build_runner/src/bootstrap/processes.dart' as _build_runner;
import 'package:source_gen/builder.dart' as _i1;
import 'package:stealth_enum_generator/src/builder.dart' as _i2;

final _builderFactories = _build_runner.BuilderFactories(
  {
    'source_gen:combining_builder': [_i1.combiningBuilder],
    'stealth_enum_generator:stealth_enum': [_i2.stealthEnumBuilder],
  },
  postProcessBuilderFactories: {
    'source_gen:part_cleanup': _i1.partCleanup,
  },
);
void main(List<String> args) async {
  _io.exitCode = await _build_runner.ChildProcess.run(
    args,
    _builderFactories,
  )!;
}
