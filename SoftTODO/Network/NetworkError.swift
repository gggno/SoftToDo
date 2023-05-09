import Foundation

enum ApiError: Error {
    case parsingError
    case noContent
    case unAuthorized
    case decodingError
    case badStatus
    case unknown(_ err: Error?)
    case forbidden
    case unprocessableContent

    var info: String {
        switch self {
        case .noContent: return "데이터가 없습니다."
        case .decodingError: return "디코딩 에러입니다."
        case .unAuthorized: return "인증되지 않은 사용자입니다."
        case .badStatus: return "에러 상태코드 입니다."
        case .unknown(let err): return "알 수 없는 에러입니다. \(err)"
        case .parsingError: return "파싱 에러입니다."
        case .forbidden: return "금지된 에러입니다."
        case .unprocessableContent: return "처리할 수 없는 콘텐츠입니다."
        }
    }
}
