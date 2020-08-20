/*
 * Copyright 2020, gRPC Authors All rights reserved.
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
enum Access: String {
  case `public`
  case `internal`
  case `private`
}

struct ImportDecl {
  var module: String
}

struct VariableDecl {
  enum Mutability {
    case constant
    case variable
  }

  var mutability: Mutability
  var name: String
  var access: Access
  var pattern: Pattern

  enum Pattern {
    case typeAndInitializer(Type, String)
    case type(Type)
    case inferTypeFromInitializer(String)
  }

  init(_ name: String, mutability: Mutability, access: Access, pattern: Pattern) {
    self.name = name
    self.mutability = mutability
    self.access = access
    self.pattern = pattern
  }
}

struct ProtocolDecl {
  var name: String
  var access: Access
  var inheritanceClause: String?
  var body: [Body]

  init(_ name: String, access: Access, inheritanceClause: String? = nil, body: [Body] = []) {
    self.name = name
    self.access = access
    self.inheritanceClause = inheritanceClause
    self.body = body
  }
}

extension ProtocolDecl {
  enum Body {
    case property(PropertyDecl)
    case method(FunctionDecl)
  }

  struct PropertyDecl {
    var name: String
    var type: String
    var getSet: GetSet

    struct GetSet: OptionSet {
      let rawValue: Int

      static let get = GetSet(rawValue: 1 << 0)
      static let set = GetSet(rawValue: 1 << 1)
      static let getAndSet: GetSet = [.get, .set]
    }
  }

  struct FunctionDecl {
    var name: String
    var parameters: [FunctionParameter]

    init(_ name: String, parameters: [FunctionParameter] = []) {
      self.name = name
      self.parameters = parameters
    }
  }
}

struct ClassDecl {
  var name: String
  var access: Access
  var isFinal: Bool

}

struct FunctionParameter {
  var name: String
  var localName: String?
  var attributes: [TypeAttribute]
  var type: Type
  var defaultExpression: String?

  init(_ name: String, localName: String? = nil, attributes: [TypeAttribute] = [], type: Type, defaultExpression: String? = nil) {
    self.name = name
    self.localName = localName
    self.attributes = attributes
    self.type = type
    self.defaultExpression = defaultExpression
  }
}

enum Type {
  case `self`
  case string
  indirect case array(of: Type)
  indirect case tuple(of: [Type])
  indirect case dictionary(key: Type, value: Type)
  indirect case optional(of: Type)
  indirect case genericIdentifier(String, [Type])
  case identifier(String)
}

enum TypeAttribute {
  case escaping
  case `inout`
}

func foo() {
  let p = ProtocolDecl("Echo_EchoClientProtocol", access: .public, body: [
    .property(.init(name: "serviceName", type: "String", getSet: [.get])),
    .method(.init("update", parameters: [
      .init("callOptions", type: .optional(of: .identifier("CallOptions")), defaultExpression: "nil"),
      .init("_", localName: "handler", attributes: [.escaping], type: .identifier("() -> Response"))
    ]))
  ])

  print(p)
}

