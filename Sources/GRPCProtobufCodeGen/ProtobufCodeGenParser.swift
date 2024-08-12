/*
 * Copyright 2024, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

internal import Foundation
internal import SwiftProtobuf
internal import SwiftProtobufPluginLibrary

internal import struct GRPCCodeGen.CodeGenerationRequest
internal import struct GRPCCodeGen.SourceGenerator

/// Parses a ``FileDescriptor`` object into a ``CodeGenerationRequest`` object.
internal struct ProtobufCodeGenParser {
  let input: FileDescriptor
  let namer: SwiftProtobufNamer
  let extraModuleImports: [String]
  let protoToModuleMappings: ProtoFileToModuleMappings
  let accessLevel: SourceGenerator.Configuration.AccessLevel

  internal init(
    input: FileDescriptor,
    protoFileModuleMappings: ProtoFileToModuleMappings,
    extraModuleImports: [String],
    accessLevel: SourceGenerator.Configuration.AccessLevel
  ) {
    self.input = input
    self.extraModuleImports = extraModuleImports
    self.protoToModuleMappings = protoFileModuleMappings
    self.namer = SwiftProtobufNamer(
      currentFile: input,
      protoFileToModuleMappings: protoFileModuleMappings
    )
    self.accessLevel = accessLevel
  }

  internal func parse() throws -> CodeGenerationRequest {
    var header = self.input.header
    // Ensuring there is a blank line after the header.
    if !header.isEmpty && !header.hasSuffix("\n\n") {
      header.append("\n")
    }
    let leadingTrivia = """
      // DO NOT EDIT.
      // swift-format-ignore-file
      //
      // Generated by the gRPC Swift generator plugin for the protocol buffer compiler.
      // Source: \(self.input.name)
      //
      // For information on using the generated types, please see the documentation:
      //   https://github.com/grpc/grpc-swift

      """
    let lookupSerializer: (String) -> String = { messageType in
      "GRPCProtobuf.ProtobufSerializer<\(messageType)>()"
    }
    let lookupDeserializer: (String) -> String = { messageType in
      "GRPCProtobuf.ProtobufDeserializer<\(messageType)>()"
    }
    let services = self.input.services.map {
      CodeGenerationRequest.ServiceDescriptor(
        descriptor: $0,
        package: input.package,
        protobufNamer: self.namer,
        file: self.input
      )
    }

    return CodeGenerationRequest(
      fileName: self.input.name,
      leadingTrivia: header + leadingTrivia,
      dependencies: self.codeDependencies,
      services: services,
      lookupSerializer: lookupSerializer,
      lookupDeserializer: lookupDeserializer
    )
  }
}

extension ProtobufCodeGenParser {
  fileprivate var codeDependencies: [CodeGenerationRequest.Dependency] {
    var codeDependencies: [CodeGenerationRequest.Dependency] = [
      .init(module: "GRPCProtobuf", accessLevel: .internal)
    ]
    // Adding as dependencies the modules containing generated code or types for
    // '.proto' files imported in the '.proto' file we are parsing.
    codeDependencies.append(
      contentsOf: (self.protoToModuleMappings.neededModules(forFile: self.input) ?? []).map {
        CodeGenerationRequest.Dependency(module: $0, accessLevel: self.accessLevel)
      }
    )
    // Adding extra imports passed in as an option to the plugin.
    codeDependencies.append(
      contentsOf: self.extraModuleImports.sorted().map {
        CodeGenerationRequest.Dependency(module: $0, accessLevel: self.accessLevel)
      }
    )
    return codeDependencies
  }
}

extension CodeGenerationRequest.ServiceDescriptor {
  fileprivate init(
    descriptor: ServiceDescriptor,
    package: String,
    protobufNamer: SwiftProtobufNamer,
    file: FileDescriptor
  ) {
    let methods = descriptor.methods.map {
      CodeGenerationRequest.ServiceDescriptor.MethodDescriptor(
        descriptor: $0,
        protobufNamer: protobufNamer
      )
    }
    let name = CodeGenerationRequest.Name(
      base: descriptor.name,
      generatedUpperCase: NamingUtils.toUpperCamelCase(descriptor.name),
      generatedLowerCase: NamingUtils.toLowerCamelCase(descriptor.name)
    )

    // Packages that are based on the path of the '.proto' file usually
    // contain dots. For example: "grpc.test".
    let namespace = CodeGenerationRequest.Name(
      base: package,
      generatedUpperCase: protobufNamer.formattedUpperCasePackage(file: file),
      generatedLowerCase: protobufNamer.formattedLowerCasePackage(file: file)
    )
    let documentation = descriptor.protoSourceComments()
    self.init(documentation: documentation, name: name, namespace: namespace, methods: methods)
  }
}

extension CodeGenerationRequest.ServiceDescriptor.MethodDescriptor {
  fileprivate init(descriptor: MethodDescriptor, protobufNamer: SwiftProtobufNamer) {
    let name = CodeGenerationRequest.Name(
      base: descriptor.name,
      generatedUpperCase: NamingUtils.toUpperCamelCase(descriptor.name),
      generatedLowerCase: NamingUtils.toLowerCamelCase(descriptor.name)
    )
    let documentation = descriptor.protoSourceComments()
    self.init(
      documentation: documentation,
      name: name,
      isInputStreaming: descriptor.clientStreaming,
      isOutputStreaming: descriptor.serverStreaming,
      inputType: protobufNamer.fullName(message: descriptor.inputType),
      outputType: protobufNamer.fullName(message: descriptor.outputType)
    )
  }
}

extension FileDescriptor {
  fileprivate var header: String {
    var header = String()
    // Field number used to collect the syntax field which is usually the first
    // declaration in a.proto file.
    // See more here:
    // https://github.com/apple/swift-protobuf/blob/main/Protos/SwiftProtobuf/google/protobuf/descriptor.proto
    let syntaxPath = IndexPath(index: 12)
    if let syntaxLocation = self.sourceCodeInfoLocation(path: syntaxPath) {
      header = syntaxLocation.asSourceComment(
        commentPrefix: "///",
        leadingDetachedPrefix: "//"
      )
    }
    return header
  }
}

extension SwiftProtobufNamer {
  internal func formattedUpperCasePackage(file: FileDescriptor) -> String {
    let unformattedPackage = self.typePrefix(forFile: file)
    return unformattedPackage.trimTrailingUnderscores()
  }

  internal func formattedLowerCasePackage(file: FileDescriptor) -> String {
    let upperCasePackage = self.formattedUpperCasePackage(file: file)
    let lowerCaseComponents = upperCasePackage.split(separator: "_").map { component in
      NamingUtils.toLowerCamelCase(String(component))
    }
    return lowerCaseComponents.joined(separator: "_")
  }
}

extension String {
  internal func trimTrailingUnderscores() -> String {
    if let index = self.lastIndex(where: { $0 != "_" }) {
      return String(self[...index])
    } else {
      return ""
    }
  }
}
