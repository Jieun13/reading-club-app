//
//  ReadingGroupService.swift
//  reading-app
//
//  Created by 백지은 on 12/29/25.
//

import Foundation
import Combine

struct GroupMember: Codable, Identifiable {
    let id: Int
    let userId: Int
    let nickname: String
    let profileImage: String?
    let introduction: String?
    let joinedAt: String
    let isLeader: Bool
}

struct CreateReadingGroupRequest: Codable {
    let name: String
    let description: String?
    let isPublic: Bool
}

struct UpdateReadingGroupRequest: Codable {
    let name: String?
    let description: String?
    let isPublic: Bool?
}

struct JoinGroupRequest: Codable {
    let introduction: String?
}

struct JoinByCodeRequest: Codable {
    let inviteCode: String
    let introduction: String?
}

class ReadingGroupService {
    static let shared = ReadingGroupService()
    private let api = APIService.shared
    
    private init() {}
    
    // 독서 모임 생성
    func createGroup(_ group: CreateReadingGroupRequest) -> AnyPublisher<ReadingGroup, Error> {
        return api.post(endpoint: "/reading-groups", body: group)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 공개 독서 모임 목록 조회
    func getPublicGroups(page: Int = 0, size: Int = 10, search: String? = nil) -> AnyPublisher<PageResponse<ReadingGroup>, Error> {
        var params = "page=\(page)&size=\(size)"
        if let search = search, !search.isEmpty {
            params += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return api.get(endpoint: "/reading-groups/public?\(params)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 내가 속한 독서 모임 목록 조회
    func getMyGroups() -> AnyPublisher<[ReadingGroup], Error> {
        return api.get(endpoint: "/reading-groups/my")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 독서 모임 상세 조회
    func getGroup(id: Int) -> AnyPublisher<ReadingGroup, Error> {
        return api.get(endpoint: "/reading-groups/\(id)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 독서 모임 수정
    func updateGroup(id: Int, group: UpdateReadingGroupRequest) -> AnyPublisher<ReadingGroup, Error> {
        return api.put(endpoint: "/reading-groups/\(id)", body: group)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 독서 모임 삭제
    func deleteGroup(id: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/reading-groups/\(id)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 초대 코드 재생성
    func regenerateInviteCode(id: Int) -> AnyPublisher<String, Error> {
        struct InviteCodeResponse: Codable {
            let inviteCode: String
        }
        return api.post(endpoint: "/reading-groups/\(id)/regenerate-invite-code", body: EmptyBody())
            .map { (response: APIResponse<InviteCodeResponse>) -> String in
                response.data.inviteCode
            }
            .eraseToAnyPublisher()
    }
    
    // 초대 링크로 그룹 정보 미리보기
    func getGroupByInviteCode(inviteCode: String) -> AnyPublisher<ReadingGroup, Error> {
        return api.get(endpoint: "/reading-groups/invite/\(inviteCode)")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 멤버 목록 조회
    func getGroupMembers(groupId: Int) -> AnyPublisher<[GroupMember], Error> {
        return api.get(endpoint: "/reading-groups/\(groupId)/members")
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 모임 가입
    func joinGroup(groupId: Int, request: JoinGroupRequest) -> AnyPublisher<GroupMember, Error> {
        return api.post(endpoint: "/reading-groups/\(groupId)/members/join", body: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 초대 코드로 가입
    func joinByInviteCode(groupId: Int, request: JoinByCodeRequest) -> AnyPublisher<GroupMember, Error> {
        return api.post(endpoint: "/reading-groups/\(groupId)/members/join-by-code", body: request)
            .map { $0.data }
            .eraseToAnyPublisher()
    }
    
    // 멤버 추방
    func removeMember(groupId: Int, userId: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/reading-groups/\(groupId)/members/\(userId)")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // 모임 나가기
    func leaveGroup(groupId: Int) -> AnyPublisher<Void, Error> {
        return api.deleteVoid(endpoint: "/reading-groups/\(groupId)/members/leave")
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

struct EmptyBody: Codable {}

