enum APIEndpoints {
    enum Auth {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let logout = "/auth/logout"
        static let refresh = "/auth/refresh"
    }

    enum Users {
        static let me = "/users/me"
    }

    enum Accounts {
        static let collection = "/accounts"

        static func detail(id: Int) -> String {
            "\(collection)/\(id)"
        }
    }

    enum Budgets {
        static let collection = "/budgets"

        static func detail(id: Int) -> String {
            "\(collection)/\(id)"
        }
    }

    enum Categories {
        static let collection = "/categories"

        static func detail(id: Int) -> String {
            "\(collection)/\(id)"
        }
    }

    enum Dashboard {
        static let summary = "/dashboard/summary"
    }

    enum Transactions {
        static let collection = "/transactions"
        static let trend = "\(collection)/trend"

        static func detail(id: Int) -> String {
            "\(collection)/\(id)"
        }
    }
}
