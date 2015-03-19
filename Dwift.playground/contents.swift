import UIKit

// Replace token & pin for uat
let token = ""
let pin = ""

//:
//: Constants
//:

class Paths {
    static let host = "https://uat.dwolla.com/oauth/rest"
    static let transactionsSubpath = "/transactions"
    static let sendSubpath = transactionsSubpath + "/send"
}

class ErrorMessages {
    static let InvalidAccessToken = "Invalid access token"
    static let InsufficientBalance = "Insufficient balance"
    static let InvalidAccountPin = "Invalid account PIN"
}

class RequestKeys {
    static let DestinationId = "destinationId"
    static let Pin = "pin"
    static let Amount = "amount"
    static let DestinationType = "destinationType"
    static let FundsSource = "fundsSource"
    static let Notes = "notes"
    static let AssumeCosts = "assumeCosts"
    static let AdditionalFees = "additionalFees"
    static let Metadata = "metadata"
    static let AssumeAdditionalFees = "assumeAdditionalFees"
    static let FacilitatorAmount = "facilitatorAmount"
}

class ResponseKeys {
    static let Success = "Success"
    static let Message = "Message"
    static let Response = "Response"
}

//:
//: Enums
//:

enum TransactionStatus {
    case Pending
    case Processed
    case Failed
    case Cancelled
    case Reclaimed
}

enum TransactionType {
    case MoneySent
    case MoneyReceived
    case Deposit
    case Withdrawal
    case Fee
}

enum DestinationType {
    case Dwolla
    case Email
    case Phone
    case Twitter
    case Facebook
    case LinkedIn
}

enum Scopes {
    case Send
}

enum HttpMethod: String {
    case GET = "GET"
    case POST = "POST"
}

//:
//: Structs
//:

struct JsonRequest {
    var url: String
    var method: HttpMethod
    var headers: [String: String?]?
    var params: [String: String]?
    var body: [String: AnyObject]?
    
    init(url: String,
        method: HttpMethod = .GET,
        headers: [String: String?]? = nil,
        params: [String: String]? = nil,
        body: [String: AnyObject]? = nil) {
            self.url = url
            self.method = method
            self.headers = headers
            self.params = params
            self.body = body
    }
}

struct JsonResponse {
    let status: Int
    let headers: [String: String]? = nil
    let body: [String: AnyObject]? = nil
}

struct Response<T> {
    let success: Bool
    let message: String
    let response: T?
}

struct Entity {
    let id: String
    let name: String
}

struct SendRequest {
    let destinationId: String
    let pin: String
    let amount: Double
    let destinationType: DestinationType?
    let fundsSource: String?
    let notes: String?
    let assumeCosts: Bool?
    let additionalFeeds: Bool?
    let metadata: [String: String]?
    let assumeAdditionalFees: Bool?
    let facilitatorAmount: Bool?
    
    init(destinationId: String,
        pin: String,
        amount: Double,
        destinationType: DestinationType? = nil,
        fundsSource: String? = nil,
        notes: String? = nil,
        assumeCosts: Bool? = nil,
        additionalFeeds: Bool? = nil,
        metadata: [String: String]? = nil,
        assumeAdditionalFees: Bool? = nil,
        facilitatorAmount: Bool? = nil) {
            self.destinationId = destinationId
            self.pin = pin
            self.amount = amount
            self.destinationType = destinationType
            self.fundsSource = fundsSource
            self.notes = notes
            self.assumeCosts = assumeCosts
            self.additionalFeeds = additionalFeeds
            self.metadata = metadata
            self.assumeAdditionalFees = assumeAdditionalFees
            self.facilitatorAmount = facilitatorAmount
    }
}

//:
//: ## Protocols
//:

protocol ToJson {
    func toJson() -> [String: AnyObject]
}

protocol ToJsonValue {
    func toJsonValue() -> String
}

protocol JsonClient {
    func execute(request: JsonRequest) -> (JsonResponse?, NSError?)
}

protocol DwollaApi {
    func send(request: SendRequest) -> Response<Double>
}

//:
//: ## Extensions
//:

// From good 'ol stackoverflow
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func map<OutKey: Hashable, OutValue>(transform: Element -> (OutKey, OutValue)) -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(Swift.map(self, transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key: Value] {
        return Dictionary(Swift.filter(self, includeElement))
    }
}

extension TransactionStatus: ToJsonValue {
    func toJsonValue() -> String {
        switch self {
        case .Cancelled:
            return "cancelled"
        default:
            return ""
        }
    }
}

extension DestinationType: ToJsonValue {
    func toJsonValue() -> String {
        switch self {
        case .Dwolla:
            return "dwolla"
        default:
            return ""
        }
    }
}

extension SendRequest: ToJson {
    func toJson() -> [String : AnyObject] {
        return [
            RequestKeys.DestinationId: self.destinationId,
            RequestKeys.Pin: self.pin,
            RequestKeys.Amount: self.amount,
            RequestKeys.DestinationType: getOptionalJson(self.destinationType)
        ]
    }
    
    private func getOptionalJson(value: Optional<ToJsonValue>) -> String {
        return value?.toJsonValue() ?? ""
    }
}

//:
//: ## Classes
//:

class NSURLRequestBuilder {
    var urlRequest = NSMutableURLRequest()
    
    func setUrl(url: String?) -> NSURLRequestBuilder {
        if let url = url {
            urlRequest.URL = NSURL(string: url)
        } else {
            urlRequest.URL = nil
        }
        return self
    }
    
    func setMethod(method: HttpMethod) -> NSURLRequestBuilder {
        urlRequest.HTTPMethod = method.rawValue
        return self
    }
    
    func setHeaders(headers: [String: String?]?) -> NSURLRequestBuilder {
        if let headers = headers {
            for header in headers {
                urlRequest.setValue(header.1, forHTTPHeaderField: header.0)
            }
        } else {
            urlRequest.allHTTPHeaderFields = nil
        }
        return self
    }
    
    func setParams(params: [String: String]?, encode: Bool = true) -> NSURLRequestBuilder {
        // TODO
        // encode?
        // fun?
        // may have to set url in build with params
        return self
    }
    
    func setBody(body: [String: AnyObject]?, error: NSErrorPointer) -> NSURLRequestBuilder {
        if let body = body,
           let data = NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions.allZeros, error: error) {
            setBody(data)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            setBody(nil)
        }
        
        return self
    }
    
    func setBody(body: NSData?) -> NSURLRequestBuilder {
        urlRequest.HTTPBody = body
        urlRequest.setValue(body?.length.description, forHTTPHeaderField: "Content-Length")
        return self
    }
    
    func setJsonRequest(jsonRequest: JsonRequest, error: NSErrorPointer) -> NSURLRequestBuilder {
        return self
            .setUrl(jsonRequest.url)
            .setMethod(jsonRequest.method)
            .setHeaders(jsonRequest.headers)
            .setParams(jsonRequest.params)
            .setBody(jsonRequest.body, error: error)
    }
    
    func reset() {
        urlRequest = NSMutableURLRequest()
    }
    
    func build() -> NSURLRequest {
        return urlRequest.copy() as! NSURLRequest
    }
}

class NSJsonClient: JsonClient {
    let dummyError = NSError(domain: "", code: 1, userInfo: nil)
    let urlBuilder = NSURLRequestBuilder()
    
    func execute(request: JsonRequest) -> (JsonResponse?, NSError?) {
        switch createURLRequest(request) {
        case let (_, .Some(error)):
            return (nil, error)
        case let (.Some(urlRequest), _):
            return execute(urlRequest)
        default:
            return (nil, dummyError)
        }
    }
    
    private func createURLRequest(jsonRequest: JsonRequest) -> (NSURLRequest?, NSError?) {
        var error: NSError?
        if let url = NSURL(string: jsonRequest.url) {
            let urlRequest = urlBuilder
                .setJsonRequest(jsonRequest, error: &error)
                .build()
            return (urlRequest, error)
        } else {
            return (nil, dummyError)
        }
    }
    
    private func execute(urlRequest: NSURLRequest) -> (JsonResponse?, NSError?) {
        switch performRequest(urlRequest) {
        case let (_, _, error) where error != nil:
            return (nil, error)
        case let (.Some(data), .Some(urlResponse), _) where urlResponse is NSHTTPURLResponse:
            return createJsonResponse(data, response: urlResponse as! NSHTTPURLResponse)
        default:
            return (nil, dummyError)
        }
    }
    
    private func performRequest(urlRequest: NSURLRequest) -> (NSData?, NSURLResponse?, NSError?) {
        let semaphore = dispatch_semaphore_create(0);
        var data: NSData? = nil
        var response: NSURLResponse? = nil
        var error: NSError? = nil
        NSURLSession.sharedSession().dataTaskWithRequest(urlRequest, completionHandler: { (taskData, taskResponse, taskError) -> Void in
            data = taskData
            response = taskResponse
            error = taskError
            dispatch_semaphore_signal(semaphore);
        }).resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return (data, response, error)
    }
    
    private func createJsonResponse(data: NSData, response: NSHTTPURLResponse) -> (JsonResponse?, NSError?) {
        var error: NSError?
        let headers = response.allHeaderFields.map { (k, v) in (k as! String, v as! String) }
        let body = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: &error) as! Dictionary<String, AnyObject>
        return (JsonResponse(status: response.statusCode, headers: headers, body: body), error)
    }
}

class DwollaApiV2: DwollaApi {
    let headers: [String: String?]
    let client: JsonClient
    let host: String
    
    convenience init(token: String) {
        self.init(token: token, host: Paths.host, client: NSJsonClient())
    }
    
    init(token: String,
        host: String,
        client: JsonClient) {
        headers = [
            "Authorization": "Bearer \(token)"
        ]
        self.host = host
        self.client = client
    }
    
    func send(request: SendRequest) -> Response<Double> {
        return post(Paths.sendSubpath, body: request.toJson()) {
            response in
            if let response = response as? Double {
                return response
            }
            return nil
        }
    }
    
    private func get<T>(subPath: String, params: [String: String]?, responseTransform: (AnyObject?) -> T?) -> Response<T> {
        let jsonRequest = JsonRequest(url: host + subPath, method: .GET, headers: headers, params: params)
        return execute(jsonRequest, responseTransform: responseTransform)
    }
    
    private func post<T>(subPath: String, body: [String: AnyObject], responseTransform: (AnyObject?) -> T?) -> Response<T> {
        let jsonRequest = JsonRequest(url: host + subPath, method: .POST, headers: headers, body: body)
        return execute(jsonRequest, responseTransform: responseTransform)
    }
    
    private func execute<T>(jsonRequest: JsonRequest, responseTransform: (AnyObject?) -> T?) -> Response<T> {
        switch client.execute(jsonRequest) {
        case let (_, .Some(error)):
            return Response(success: false, message: error.description, response: nil)
        case let (.Some(jsonResponse), _):
            return parse(jsonResponse.body, transform: responseTransform)
        default:
            return Response(success: false, message: "Unexpected error", response: nil)
        }
    }
    
    private func parse<T>(body: [String: AnyObject]?, transform: (AnyObject?) -> T?) -> Response<T> {
        if let body = body,
           let success = body[ResponseKeys.Success] as? Bool,
           let message = body[ResponseKeys.Message] as? String,
           let response = transform(body[ResponseKeys.Response]) {
            return Response(success: success, message: message, response: response)
        } else {
            return Response(success: false, message: "Unknown error", response: nil)
        }
    }
}

//:
//: ## Send
//:

// happy path
let client = DwollaApiV2(token: token)
let sendRequest = SendRequest(destinationId: "812-741-6790", pin: pin, amount: 0.01)
let sendResponse = client.send(sendRequest)

// invalid pin

// invalid amount








