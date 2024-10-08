import SwiftUI

struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()
    @State private var isGridView = false

    var body: some View {
        NavigationView {
            Group {
                if !isGridView {
                    List(viewModel.users) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
                            HStack {
                                AsyncImage(url: URL(string: user.picture.thumbnail)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                }

                                VStack(alignment: .leading) {
                                    Text("\(user.name.first) \(user.name.last)")
                                        .font(.headline)
                                    Text("\(user.dob.date)")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .onAppear {
                            if viewModel.shouldLoadMoreData(currentItem: user) {
                                Task {
                                    await viewModel.fetchUsers()
                                }
                            }
                        }
                    }
                    .navigationTitle("Users")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Picker(selection: $isGridView, label: Text("Display")) {
                                Image(systemName: "rectangle.grid.1x2.fill")
                                    .tag(true)
                                    .accessibilityLabel(Text("Grid view"))
                                Image(systemName: "list.bullet")
                                    .tag(false)
                                    .accessibilityLabel(Text("List view"))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    await viewModel.reloadUsers()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .imageScale(.large)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                            ForEach(viewModel.users) { user in
                                NavigationLink(destination: UserDetailView(user: user)) {
                                    VStack {
                                        AsyncImage(url: URL(string: user.picture.medium)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 150, height: 150)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            ProgressView()
                                                .frame(width: 150, height: 150)
                                                .clipShape(Circle())
                                        }

                                        Text("\(user.name.first) \(user.name.last)")
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .onAppear {
                                    if viewModel.shouldLoadMoreData(currentItem: user) {
                                        Task {
                                            await viewModel.fetchUsers()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Users")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Picker(selection: $isGridView, label: Text("Display")) {
                                Image(systemName: "rectangle.grid.1x2.fill")
                                    .tag(true)
                                    .accessibilityLabel(Text("Grid view"))
                                Image(systemName: "list.bullet")
                                    .tag(false)
                                    .accessibilityLabel(Text("List view"))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    await viewModel.reloadUsers()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .imageScale(.large)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchUsers()
            }
        }
    }
}

struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView()
    }
}
