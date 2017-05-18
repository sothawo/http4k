package cookbook

import org.http4k.core.HttpHandler
import org.http4k.core.Method
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.template.HandlebarsTemplates
import org.http4k.template.ViewModel

// this view has the default template path of: cookbook/Person.hbs, although that is overridable
data class Person(val name: String, val age: Int) : ViewModel

/**
 * Example showing how to use the Templating modules - in this case Handlebars
 */
fun main(args: Array<String>) {

    val renderer = HandlebarsTemplates().HotReload("src/test/resources")

    val app: HttpHandler = {
        val viewModel = Person("Bob", 45)
        val renderedView = renderer(viewModel)
        Response(OK).body(renderedView)
    }

    println(app(Request(Method.GET, "/someUrl")))
}

