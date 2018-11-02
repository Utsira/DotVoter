import Foundation	
public typealias CodableError = Error & Codable & Equatable

public enum CardError: String, Swift.Error, Codable {
    case cardAlreadyExists, cardCouldNotBeFound, cardCannotBeDownVotedBelowOne, cardCanOnlyBeEditedByAuthor
}	