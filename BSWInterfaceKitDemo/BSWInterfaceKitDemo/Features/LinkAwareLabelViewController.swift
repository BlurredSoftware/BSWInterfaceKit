//
//  Created by Pierluigi Cifani on 26/03/2020.
//  Copyright © 2020 The Left Bit. All rights reserved.
//

import UIKit
import BSWInterfaceKit

class LinkAwareLabelViewController: UIViewController {
    let label = LinkAwareLabel()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addAutolayoutSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.numberOfLines = 0
        label.attributedText = TextStyler.styler.attributedString(
            """
            Its just one of those days
            Where you don't want to wake up
            Everything is fucked
            Everybody sucks
            """
            )
            .addingLink(onSubstring: "is fucked", linkURL: URL(string: "https://www.youtube.com/watch?v=ZpUYjpKg9KY")!, linkColor: .systemBlue)
            .addingLink(onSubstring: "those days", linkURL: URL(string: "https://www.youtube.com/watch?v=ZpUYjpKg9KY")!, linkColor: .systemRed)
            .settingParagraphStyle({
                let p = NSMutableParagraphStyle()
                p.alignment = .center
                return p
            }())
    }
}