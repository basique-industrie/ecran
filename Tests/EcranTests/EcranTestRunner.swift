import Foundation

@main
enum EcranTestRunner {
    static func main() async {
        let code = await EcranSelfTests.run()
        if code != 0 {
            exit(Int32(code))
        }
    }
}
