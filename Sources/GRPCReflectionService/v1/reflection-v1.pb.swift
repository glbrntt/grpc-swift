// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: reflection.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// Copyright 2016 The gRPC Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Service exported by server reflection.  A more complete description of how
// server reflection works can be found at
// https://github.com/grpc/grpc/blob/master/doc/server-reflection.md
//
// The canonical version of this proto can be found at
// https://github.com/grpc/grpc-proto/blob/master/grpc/reflection/v1/reflection.proto

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// The message sent by the client when calling ServerReflectionInfo method.
public struct Grpc_Reflection_V1_ServerReflectionRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var host: String = String()

  /// To use reflection service, the client should set one of the following
  /// fields in message_request. The server distinguishes requests by their
  /// defined field and then handles them using corresponding methods.
  public var messageRequest: Grpc_Reflection_V1_ServerReflectionRequest.OneOf_MessageRequest? = nil

  /// Find a proto file by the file name.
  public var fileByFilename: String {
    get {
      if case .fileByFilename(let v)? = messageRequest {return v}
      return String()
    }
    set {messageRequest = .fileByFilename(newValue)}
  }

  /// Find the proto file that declares the given fully-qualified symbol name.
  /// This field should be a fully-qualified symbol name
  /// (e.g. <package>.<service>[.<method>] or <package>.<type>).
  public var fileContainingSymbol: String {
    get {
      if case .fileContainingSymbol(let v)? = messageRequest {return v}
      return String()
    }
    set {messageRequest = .fileContainingSymbol(newValue)}
  }

  /// Find the proto file which defines an extension extending the given
  /// message type with the given field number.
  public var fileContainingExtension: Grpc_Reflection_V1_ExtensionRequest {
    get {
      if case .fileContainingExtension(let v)? = messageRequest {return v}
      return Grpc_Reflection_V1_ExtensionRequest()
    }
    set {messageRequest = .fileContainingExtension(newValue)}
  }

  /// Finds the tag numbers used by all known extensions of the given message
  /// type, and appends them to ExtensionNumberResponse in an undefined order.
  /// Its corresponding method is best-effort: it's not guaranteed that the
  /// reflection service will implement this method, and it's not guaranteed
  /// that this method will provide all extensions. Returns
  /// StatusCode::UNIMPLEMENTED if it's not implemented.
  /// This field should be a fully-qualified type name. The format is
  /// <package>.<type>
  public var allExtensionNumbersOfType: String {
    get {
      if case .allExtensionNumbersOfType(let v)? = messageRequest {return v}
      return String()
    }
    set {messageRequest = .allExtensionNumbersOfType(newValue)}
  }

  /// List the full names of registered services. The content will not be
  /// checked.
  public var listServices: String {
    get {
      if case .listServices(let v)? = messageRequest {return v}
      return String()
    }
    set {messageRequest = .listServices(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// To use reflection service, the client should set one of the following
  /// fields in message_request. The server distinguishes requests by their
  /// defined field and then handles them using corresponding methods.
  public enum OneOf_MessageRequest: Equatable, Sendable {
    /// Find a proto file by the file name.
    case fileByFilename(String)
    /// Find the proto file that declares the given fully-qualified symbol name.
    /// This field should be a fully-qualified symbol name
    /// (e.g. <package>.<service>[.<method>] or <package>.<type>).
    case fileContainingSymbol(String)
    /// Find the proto file which defines an extension extending the given
    /// message type with the given field number.
    case fileContainingExtension(Grpc_Reflection_V1_ExtensionRequest)
    /// Finds the tag numbers used by all known extensions of the given message
    /// type, and appends them to ExtensionNumberResponse in an undefined order.
    /// Its corresponding method is best-effort: it's not guaranteed that the
    /// reflection service will implement this method, and it's not guaranteed
    /// that this method will provide all extensions. Returns
    /// StatusCode::UNIMPLEMENTED if it's not implemented.
    /// This field should be a fully-qualified type name. The format is
    /// <package>.<type>
    case allExtensionNumbersOfType(String)
    /// List the full names of registered services. The content will not be
    /// checked.
    case listServices(String)

  }

  public init() {}
}

/// The type name and extension number sent by the client when requesting
/// file_containing_extension.
public struct Grpc_Reflection_V1_ExtensionRequest: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Fully-qualified type name. The format should be <package>.<type>
  public var containingType: String = String()

  public var extensionNumber: Int32 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// The message sent by the server to answer ServerReflectionInfo method.
public struct Grpc_Reflection_V1_ServerReflectionResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var validHost: String = String()

  public var originalRequest: Grpc_Reflection_V1_ServerReflectionRequest {
    get {return _originalRequest ?? Grpc_Reflection_V1_ServerReflectionRequest()}
    set {_originalRequest = newValue}
  }
  /// Returns true if `originalRequest` has been explicitly set.
  public var hasOriginalRequest: Bool {return self._originalRequest != nil}
  /// Clears the value of `originalRequest`. Subsequent reads from it will return its default value.
  public mutating func clearOriginalRequest() {self._originalRequest = nil}

  /// The server sets one of the following fields according to the message_request
  /// in the request.
  public var messageResponse: Grpc_Reflection_V1_ServerReflectionResponse.OneOf_MessageResponse? = nil

  /// This message is used to answer file_by_filename, file_containing_symbol,
  /// file_containing_extension requests with transitive dependencies.
  /// As the repeated label is not allowed in oneof fields, we use a
  /// FileDescriptorResponse message to encapsulate the repeated fields.
  /// The reflection service is allowed to avoid sending FileDescriptorProtos
  /// that were previously sent in response to earlier requests in the stream.
  public var fileDescriptorResponse: Grpc_Reflection_V1_FileDescriptorResponse {
    get {
      if case .fileDescriptorResponse(let v)? = messageResponse {return v}
      return Grpc_Reflection_V1_FileDescriptorResponse()
    }
    set {messageResponse = .fileDescriptorResponse(newValue)}
  }

  /// This message is used to answer all_extension_numbers_of_type requests.
  public var allExtensionNumbersResponse: Grpc_Reflection_V1_ExtensionNumberResponse {
    get {
      if case .allExtensionNumbersResponse(let v)? = messageResponse {return v}
      return Grpc_Reflection_V1_ExtensionNumberResponse()
    }
    set {messageResponse = .allExtensionNumbersResponse(newValue)}
  }

  /// This message is used to answer list_services requests.
  public var listServicesResponse: Grpc_Reflection_V1_ListServiceResponse {
    get {
      if case .listServicesResponse(let v)? = messageResponse {return v}
      return Grpc_Reflection_V1_ListServiceResponse()
    }
    set {messageResponse = .listServicesResponse(newValue)}
  }

  /// This message is used when an error occurs.
  public var errorResponse: Grpc_Reflection_V1_ErrorResponse {
    get {
      if case .errorResponse(let v)? = messageResponse {return v}
      return Grpc_Reflection_V1_ErrorResponse()
    }
    set {messageResponse = .errorResponse(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// The server sets one of the following fields according to the message_request
  /// in the request.
  public enum OneOf_MessageResponse: Equatable, Sendable {
    /// This message is used to answer file_by_filename, file_containing_symbol,
    /// file_containing_extension requests with transitive dependencies.
    /// As the repeated label is not allowed in oneof fields, we use a
    /// FileDescriptorResponse message to encapsulate the repeated fields.
    /// The reflection service is allowed to avoid sending FileDescriptorProtos
    /// that were previously sent in response to earlier requests in the stream.
    case fileDescriptorResponse(Grpc_Reflection_V1_FileDescriptorResponse)
    /// This message is used to answer all_extension_numbers_of_type requests.
    case allExtensionNumbersResponse(Grpc_Reflection_V1_ExtensionNumberResponse)
    /// This message is used to answer list_services requests.
    case listServicesResponse(Grpc_Reflection_V1_ListServiceResponse)
    /// This message is used when an error occurs.
    case errorResponse(Grpc_Reflection_V1_ErrorResponse)

  }

  public init() {}

  fileprivate var _originalRequest: Grpc_Reflection_V1_ServerReflectionRequest? = nil
}

/// Serialized FileDescriptorProto messages sent by the server answering
/// a file_by_filename, file_containing_symbol, or file_containing_extension
/// request.
public struct Grpc_Reflection_V1_FileDescriptorResponse: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Serialized FileDescriptorProto messages. We avoid taking a dependency on
  /// descriptor.proto, which uses proto2 only features, by making them opaque
  /// bytes instead.
  public var fileDescriptorProto: [Data] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// A list of extension numbers sent by the server answering
/// all_extension_numbers_of_type request.
public struct Grpc_Reflection_V1_ExtensionNumberResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Full name of the base type, including the package name. The format
  /// is <package>.<type>
  public var baseTypeName: String = String()

  public var extensionNumber: [Int32] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// A list of ServiceResponse sent by the server answering list_services request.
public struct Grpc_Reflection_V1_ListServiceResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The information of each service may be expanded in the future, so we use
  /// ServiceResponse message to encapsulate it.
  public var service: [Grpc_Reflection_V1_ServiceResponse] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// The information of a single service used by ListServiceResponse to answer
/// list_services request.
public struct Grpc_Reflection_V1_ServiceResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Full name of a registered service, including its package name. The format
  /// is <package>.<service>
  public var name: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// The error code and error message sent by the server when an error occurs.
public struct Grpc_Reflection_V1_ErrorResponse: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// This field uses the error codes defined in grpc::StatusCode.
  public var errorCode: Int32 = 0

  public var errorMessage: String = String()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "grpc.reflection.v1"

extension Grpc_Reflection_V1_ServerReflectionRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ServerReflectionRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "host"),
    3: .standard(proto: "file_by_filename"),
    4: .standard(proto: "file_containing_symbol"),
    5: .standard(proto: "file_containing_extension"),
    6: .standard(proto: "all_extension_numbers_of_type"),
    7: .standard(proto: "list_services"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.host) }()
      case 3: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.messageRequest != nil {try decoder.handleConflictingOneOf()}
          self.messageRequest = .fileByFilename(v)
        }
      }()
      case 4: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.messageRequest != nil {try decoder.handleConflictingOneOf()}
          self.messageRequest = .fileContainingSymbol(v)
        }
      }()
      case 5: try {
        var v: Grpc_Reflection_V1_ExtensionRequest?
        var hadOneofValue = false
        if let current = self.messageRequest {
          hadOneofValue = true
          if case .fileContainingExtension(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.messageRequest = .fileContainingExtension(v)
        }
      }()
      case 6: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.messageRequest != nil {try decoder.handleConflictingOneOf()}
          self.messageRequest = .allExtensionNumbersOfType(v)
        }
      }()
      case 7: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.messageRequest != nil {try decoder.handleConflictingOneOf()}
          self.messageRequest = .listServices(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.host.isEmpty {
      try visitor.visitSingularStringField(value: self.host, fieldNumber: 1)
    }
    switch self.messageRequest {
    case .fileByFilename?: try {
      guard case .fileByFilename(let v)? = self.messageRequest else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 3)
    }()
    case .fileContainingSymbol?: try {
      guard case .fileContainingSymbol(let v)? = self.messageRequest else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 4)
    }()
    case .fileContainingExtension?: try {
      guard case .fileContainingExtension(let v)? = self.messageRequest else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }()
    case .allExtensionNumbersOfType?: try {
      guard case .allExtensionNumbersOfType(let v)? = self.messageRequest else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 6)
    }()
    case .listServices?: try {
      guard case .listServices(let v)? = self.messageRequest else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 7)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ServerReflectionRequest, rhs: Grpc_Reflection_V1_ServerReflectionRequest) -> Bool {
    if lhs.host != rhs.host {return false}
    if lhs.messageRequest != rhs.messageRequest {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ExtensionRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ExtensionRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "containing_type"),
    2: .standard(proto: "extension_number"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.containingType) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.extensionNumber) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.containingType.isEmpty {
      try visitor.visitSingularStringField(value: self.containingType, fieldNumber: 1)
    }
    if self.extensionNumber != 0 {
      try visitor.visitSingularInt32Field(value: self.extensionNumber, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ExtensionRequest, rhs: Grpc_Reflection_V1_ExtensionRequest) -> Bool {
    if lhs.containingType != rhs.containingType {return false}
    if lhs.extensionNumber != rhs.extensionNumber {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ServerReflectionResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ServerReflectionResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "valid_host"),
    2: .standard(proto: "original_request"),
    4: .standard(proto: "file_descriptor_response"),
    5: .standard(proto: "all_extension_numbers_response"),
    6: .standard(proto: "list_services_response"),
    7: .standard(proto: "error_response"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.validHost) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._originalRequest) }()
      case 4: try {
        var v: Grpc_Reflection_V1_FileDescriptorResponse?
        var hadOneofValue = false
        if let current = self.messageResponse {
          hadOneofValue = true
          if case .fileDescriptorResponse(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.messageResponse = .fileDescriptorResponse(v)
        }
      }()
      case 5: try {
        var v: Grpc_Reflection_V1_ExtensionNumberResponse?
        var hadOneofValue = false
        if let current = self.messageResponse {
          hadOneofValue = true
          if case .allExtensionNumbersResponse(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.messageResponse = .allExtensionNumbersResponse(v)
        }
      }()
      case 6: try {
        var v: Grpc_Reflection_V1_ListServiceResponse?
        var hadOneofValue = false
        if let current = self.messageResponse {
          hadOneofValue = true
          if case .listServicesResponse(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.messageResponse = .listServicesResponse(v)
        }
      }()
      case 7: try {
        var v: Grpc_Reflection_V1_ErrorResponse?
        var hadOneofValue = false
        if let current = self.messageResponse {
          hadOneofValue = true
          if case .errorResponse(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.messageResponse = .errorResponse(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.validHost.isEmpty {
      try visitor.visitSingularStringField(value: self.validHost, fieldNumber: 1)
    }
    try { if let v = self._originalRequest {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    switch self.messageResponse {
    case .fileDescriptorResponse?: try {
      guard case .fileDescriptorResponse(let v)? = self.messageResponse else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }()
    case .allExtensionNumbersResponse?: try {
      guard case .allExtensionNumbersResponse(let v)? = self.messageResponse else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }()
    case .listServicesResponse?: try {
      guard case .listServicesResponse(let v)? = self.messageResponse else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    }()
    case .errorResponse?: try {
      guard case .errorResponse(let v)? = self.messageResponse else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ServerReflectionResponse, rhs: Grpc_Reflection_V1_ServerReflectionResponse) -> Bool {
    if lhs.validHost != rhs.validHost {return false}
    if lhs._originalRequest != rhs._originalRequest {return false}
    if lhs.messageResponse != rhs.messageResponse {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_FileDescriptorResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".FileDescriptorResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "file_descriptor_proto"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedBytesField(value: &self.fileDescriptorProto) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.fileDescriptorProto.isEmpty {
      try visitor.visitRepeatedBytesField(value: self.fileDescriptorProto, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_FileDescriptorResponse, rhs: Grpc_Reflection_V1_FileDescriptorResponse) -> Bool {
    if lhs.fileDescriptorProto != rhs.fileDescriptorProto {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ExtensionNumberResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ExtensionNumberResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "base_type_name"),
    2: .standard(proto: "extension_number"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.baseTypeName) }()
      case 2: try { try decoder.decodeRepeatedInt32Field(value: &self.extensionNumber) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.baseTypeName.isEmpty {
      try visitor.visitSingularStringField(value: self.baseTypeName, fieldNumber: 1)
    }
    if !self.extensionNumber.isEmpty {
      try visitor.visitPackedInt32Field(value: self.extensionNumber, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ExtensionNumberResponse, rhs: Grpc_Reflection_V1_ExtensionNumberResponse) -> Bool {
    if lhs.baseTypeName != rhs.baseTypeName {return false}
    if lhs.extensionNumber != rhs.extensionNumber {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ListServiceResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ListServiceResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "service"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.service) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.service.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.service, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ListServiceResponse, rhs: Grpc_Reflection_V1_ListServiceResponse) -> Bool {
    if lhs.service != rhs.service {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ServiceResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ServiceResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.name) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ServiceResponse, rhs: Grpc_Reflection_V1_ServiceResponse) -> Bool {
    if lhs.name != rhs.name {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Grpc_Reflection_V1_ErrorResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".ErrorResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "error_code"),
    2: .standard(proto: "error_message"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.errorCode) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.errorMessage) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.errorCode != 0 {
      try visitor.visitSingularInt32Field(value: self.errorCode, fieldNumber: 1)
    }
    if !self.errorMessage.isEmpty {
      try visitor.visitSingularStringField(value: self.errorMessage, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Grpc_Reflection_V1_ErrorResponse, rhs: Grpc_Reflection_V1_ErrorResponse) -> Bool {
    if lhs.errorCode != rhs.errorCode {return false}
    if lhs.errorMessage != rhs.errorMessage {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
