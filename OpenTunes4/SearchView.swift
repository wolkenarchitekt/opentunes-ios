import Foundation
import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

class KeyboardObserver: ObservableObject {
    private var observers = [NSObjectProtocol]()
    @Published var keyboardIsVisible = false
     
    init() {
        let handler: (Notification) -> Void = { [weak self] notification in
            if notification.name == UIResponder.keyboardWillHideNotification {
                print("Keyboard hidden")
                self?.keyboardIsVisible = false
            } else {
                print("keyboard shown")
                self?.keyboardIsVisible = true
            }
        }
        let names: [Notification.Name] = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification,
        ]
        observers = names.map({ name in
            NotificationCenter.default.addObserver(forName: name,
                                                   object: nil,
                                                   queue: .main,
                                                   using: handler)
        })
    }
}

struct SearchView: View {
    @State private var searchAll: String = ""
    
    @ObservedObject fileprivate var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        HStack() {
            HStack() {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchAll)
                Menu {
                    Button(action: {
                    }) {
                        Text("Artist")
                    }
                    Button(action: {
                    }) {
                        Text("Title")
                    }
                    Button(action: {
                    }) {
                        Text("BPM")
                    }
                    Button(action: {
                    }) {
                        Text("Key")
                    }
                    Button(action: {
                    }) {
                        Text("Recently Added")
                    }
                }
                label: {
                    if !self.keyboardObserver.keyboardIsVisible {
//                        Image(systemName: "line.horizontal.3.decrease")
//                            .foregroundColor(.white)
                    }
                }
                    
                
            }.padding().background(Color(red: 0.2, green: 0.2, blue: 0.2))
            
            if !self.keyboardObserver.keyboardIsVisible {
                MenuButton(systemName: "line.horizontal.3")
            }
            
            AirPlayView().frame(width: 50, height: 50)
            
            if self.keyboardObserver.keyboardIsVisible {
                Button(action: {
                    searchAll = ""
                    self.hideKeyboard()
                }, label: {
                    Text("Cancel")
                })
            } else {
//                Menu {
//                    Button(action: {
//                    }) {
//                        Text("Artist")
//                    }
//                    Button(action: {
//                    }) {
//                        Text("Title")
//                    }
//                    Button(action: {
//                    }) {
//                        Text("BPM")
//                    }
//                    Button(action: {
//                    }) {
//                        Text("Key")
//                    }
//                    Button(action: {
//                    }) {
//                        Text("Recently Added")
//                    }
//                }
//                label: {
//                    Image(systemName: "arrow.up.arrow.down")
//                        .foregroundColor(.white)
//                        .padding(10)
//                }
            }
            
        }
        .padding(.top, 10)
        .padding(.horizontal, 10)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
