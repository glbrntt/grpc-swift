// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: route_guide.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// Copyright 2015 gRPC authors.
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

/// Points are represented as latitude-longitude pairs in the E7 representation
/// (degrees multiplied by 10**7 and rounded to the nearest integer).
/// Latitudes should be in the range +/- 90 degrees and longitude should be in
/// the range +/- 180 degrees (inclusive).
struct Routeguide_Point: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var latitude: Int32 = 0

  var longitude: Int32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// A latitude-longitude rectangle, represented as two diagonally opposite
/// points "lo" and "hi".
struct Routeguide_Rectangle: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// One corner of the rectangle.
  var lo: Routeguide_Point {
    get {return _lo ?? Routeguide_Point()}
    set {_lo = newValue}
  }
  /// Returns true if `lo` has been explicitly set.
  var hasLo: Bool {return self._lo != nil}
  /// Clears the value of `lo`. Subsequent reads from it will return its default value.
  mutating func clearLo() {self._lo = nil}

  /// The other corner of the rectangle.
  var hi: Routeguide_Point {
    get {return _hi ?? Routeguide_Point()}
    set {_hi = newValue}
  }
  /// Returns true if `hi` has been explicitly set.
  var hasHi: Bool {return self._hi != nil}
  /// Clears the value of `hi`. Subsequent reads from it will return its default value.
  mutating func clearHi() {self._hi = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _lo: Routeguide_Point? = nil
  fileprivate var _hi: Routeguide_Point? = nil
}

/// A feature names something at a given point.
///
/// If a feature could not be named, the name is empty.
struct Routeguide_Feature: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The name of the feature.
  var name: String = String()

  /// The point where the feature is detected.
  var location: Routeguide_Point {
    get {return _location ?? Routeguide_Point()}
    set {_location = newValue}
  }
  /// Returns true if `location` has been explicitly set.
  var hasLocation: Bool {return self._location != nil}
  /// Clears the value of `location`. Subsequent reads from it will return its default value.
  mutating func clearLocation() {self._location = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _location: Routeguide_Point? = nil
}

/// A RouteNote is a message sent while at a given point.
struct Routeguide_RouteNote: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The location from which the message is sent.
  var location: Routeguide_Point {
    get {return _location ?? Routeguide_Point()}
    set {_location = newValue}
  }
  /// Returns true if `location` has been explicitly set.
  var hasLocation: Bool {return self._location != nil}
  /// Clears the value of `location`. Subsequent reads from it will return its default value.
  mutating func clearLocation() {self._location = nil}

  /// The message to be sent.
  var message: String = String()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _location: Routeguide_Point? = nil
}

/// A RouteSummary is received in response to a RecordRoute rpc.
///
/// It contains the number of individual points received, the number of
/// detected features, and the total distance covered as the cumulative sum of
/// the distance between each point.
struct Routeguide_RouteSummary: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The number of points received.
  var pointCount: Int32 = 0

  /// The number of known features passed while traversing the route.
  var featureCount: Int32 = 0

  /// The distance covered in metres.
  var distance: Int32 = 0

  /// The duration of the traversal in seconds.
  var elapsedTime: Int32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "routeguide"

extension Routeguide_Point: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Point"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "latitude"),
    2: .same(proto: "longitude"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.latitude) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.longitude) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.latitude != 0 {
      try visitor.visitSingularInt32Field(value: self.latitude, fieldNumber: 1)
    }
    if self.longitude != 0 {
      try visitor.visitSingularInt32Field(value: self.longitude, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Routeguide_Point, rhs: Routeguide_Point) -> Bool {
    if lhs.latitude != rhs.latitude {return false}
    if lhs.longitude != rhs.longitude {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Routeguide_Rectangle: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Rectangle"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "lo"),
    2: .same(proto: "hi"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._lo) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._hi) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._lo {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._hi {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Routeguide_Rectangle, rhs: Routeguide_Rectangle) -> Bool {
    if lhs._lo != rhs._lo {return false}
    if lhs._hi != rhs._hi {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Routeguide_Feature: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Feature"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "location"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.name) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._location) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
    }
    try { if let v = self._location {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Routeguide_Feature, rhs: Routeguide_Feature) -> Bool {
    if lhs.name != rhs.name {return false}
    if lhs._location != rhs._location {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Routeguide_RouteNote: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".RouteNote"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "location"),
    2: .same(proto: "message"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._location) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.message) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._location {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    } }()
    if !self.message.isEmpty {
      try visitor.visitSingularStringField(value: self.message, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Routeguide_RouteNote, rhs: Routeguide_RouteNote) -> Bool {
    if lhs._location != rhs._location {return false}
    if lhs.message != rhs.message {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Routeguide_RouteSummary: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".RouteSummary"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "point_count"),
    2: .standard(proto: "feature_count"),
    3: .same(proto: "distance"),
    4: .standard(proto: "elapsed_time"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.pointCount) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.featureCount) }()
      case 3: try { try decoder.decodeSingularInt32Field(value: &self.distance) }()
      case 4: try { try decoder.decodeSingularInt32Field(value: &self.elapsedTime) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.pointCount != 0 {
      try visitor.visitSingularInt32Field(value: self.pointCount, fieldNumber: 1)
    }
    if self.featureCount != 0 {
      try visitor.visitSingularInt32Field(value: self.featureCount, fieldNumber: 2)
    }
    if self.distance != 0 {
      try visitor.visitSingularInt32Field(value: self.distance, fieldNumber: 3)
    }
    if self.elapsedTime != 0 {
      try visitor.visitSingularInt32Field(value: self.elapsedTime, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Routeguide_RouteSummary, rhs: Routeguide_RouteSummary) -> Bool {
    if lhs.pointCount != rhs.pointCount {return false}
    if lhs.featureCount != rhs.featureCount {return false}
    if lhs.distance != rhs.distance {return false}
    if lhs.elapsedTime != rhs.elapsedTime {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
